import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import '../../../core/pdf/pdf_engine.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repos/bookmark_repository.dart';
import '../../../data/repos/document_repository.dart';
import '../../../data/repos/progress_repository.dart';
import '../../../data/repos/toc_repository.dart';
import 'reader_session.dart';

export 'reader_session.dart' show ReaderPanelTab;

/// PDF 阅读页控制器：单页翻页、渲染缓存、进度保存、书签面板状态。
class ReaderController extends ReaderSession {
  ReaderController({
    required DocumentRepository documents,
    required ProgressRepository progress,
    required BookmarkRepository bookmarks,
    required TocRepository toc,
    required this.documentId,
  }) : _documents = documents,
       _progress = progress,
       _bookmarks = bookmarks,
       _toc = toc;

  final DocumentRepository _documents;
  final ProgressRepository _progress;
  final BookmarkRepository _bookmarks;
  final TocRepository _toc;
  final String documentId;

  static const int _cacheLimit = 3;

  DocumentRow? _document;
  PdfDocumentHandle? _handle;
  final LinkedHashMap<int, ui.Image> _images = LinkedHashMap<int, ui.Image>();
  int? _cachePixelWidth;
  Timer? _saveTimer;
  bool _disposed = false;

  int _pageIndex = 0;
  int _pageCount = 0;
  bool _loading = true;
  bool _bookmarksVisible = false;
  String? _errorMessage;
  List<BookmarkRow> _bookmarkItems = const <BookmarkRow>[];
  List<TocEntryRow> _tocItems = const <TocEntryRow>[];
  bool _tocLoading = false;
  String? _tocError;
  ReaderPanelTab _panelTab = ReaderPanelTab.bookmarks;

  @override
  DocumentRow? get document => _document;
  int get pageIndex => _pageIndex;
  int get pageCount => _pageCount;
  @override
  bool get loading => _loading;
  @override
  bool get bookmarksVisible => _bookmarksVisible;
  @override
  String? get errorMessage => _errorMessage;
  @override
  List<BookmarkRow> get bookmarkItems => _bookmarkItems;
  @override
  ReaderPanelTab get panelTab => _panelTab;
  @override
  List<TocEntryRow> get tocItems => _tocItems;
  @override
  bool get tocLoading => _tocLoading;
  @override
  String? get tocError => _tocError;

  @override
  bool get hasTextLayer => _document?.hasTextLayer ?? true;

  @override
  int? get currentPageIndex => _pageIndex;

  @override
  String? get currentHref => null;

  @override
  bool get supportsTypography => false;

  bool get hasPrevious => _pageIndex > 0;
  bool get hasNext => _pageIndex < _pageCount - 1;

  Future<void> load() async {
    try {
      final document = await _documents.byId(documentId);
      if (document == null) {
        _fail('文档不存在，可能已被删除');
        return;
      }
      _document = document;
      final handle = await _documents.openHandle(document);
      _handle = handle;
      _pageCount = handle.pageCount;
      final saved = await _progress.load(documentId);
      _pageIndex = (saved?.pageIndex ?? 0)
          .clamp(0, _pageCount == 0 ? 0 : _pageCount - 1)
          .toInt();
      _bookmarkItems = await _bookmarks.list(documentId);
      _loading = false;
      notifyListeners();
      // 目录不阻塞首屏：先出页面，解析结果回来再刷新面板。
      unawaited(_loadToc(handle));
    } on DocumentMissingException {
      _fail('文件已丢失，请回到书架重新导入');
    } catch (error) {
      _fail('打开文档失败：$error');
    }
  }

  void _fail(String message) {
    _errorMessage = message;
    _loading = false;
    notifyListeners();
  }

  @override
  void nextPage() {
    if (hasNext) {
      unawaited(goTo(_pageIndex + 1));
    }
  }

  @override
  void previousPage() {
    if (hasPrevious) {
      unawaited(goTo(_pageIndex - 1));
    }
  }

  Future<void> goTo(int index) async {
    if (_pageCount == 0) return;
    final target = index.clamp(0, _pageCount - 1).toInt();
    if (target == _pageIndex) return;
    _pageIndex = target;
    notifyListeners();
    _scheduleSave();
  }

  /// 取指定页的位图；命中缓存直接返回。
  Future<ui.Image?> imageFor(int index, int pixelWidth) async {
    if (_cachePixelWidth != pixelWidth) {
      _clearImages();
      _cachePixelWidth = pixelWidth;
    }
    final cached = _images.remove(index);
    if (cached != null) {
      _images[index] = cached;
      return cached;
    }
    final handle = _handle;
    if (handle == null) return null;
    final image = await handle.renderPage(index, pixelWidth: pixelWidth);
    if (_disposed) {
      image.dispose();
      return null;
    }
    _images[index] = image;
    while (_images.length > _cacheLimit) {
      final oldestKey = _images.keys.first;
      _images.remove(oldestKey)?.dispose();
    }
    return image;
  }

  @override
  void openBookmarks() {
    if (_bookmarksVisible) return;
    _bookmarksVisible = true;
    notifyListeners();
  }

  @override
  void selectPanelTab(ReaderPanelTab tab) {
    if (_panelTab == tab) return;
    _panelTab = tab;
    notifyListeners();
  }

  /// 读取目录：优先缓存，首次打开解析并落库。
  Future<void> _loadToc(PdfDocumentHandle handle) async {
    _tocLoading = true;
    if (!_disposed) notifyListeners();
    try {
      final items = await _toc.loadOrParse(
        documentId: documentId,
        readOutline: handle.outline,
      );
      _tocItems = items;
      _tocError = null;
    } catch (error, stack) {
      _tocError = '目录读取失败';
      AppLogger.log(
        '目录读取失败',
        level: 'WARN',
        tag: 'TOC',
        detail: '$error\n$stack',
      );
    } finally {
      _tocLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void closeBookmarks() {
    if (!_bookmarksVisible) return;
    _bookmarksVisible = false;
    notifyListeners();
  }

  Future<void> refreshBookmarks() async {
    _bookmarkItems = await _bookmarks.list(documentId);
    if (!_disposed) notifyListeners();
  }

  /// 在当前位置添加书签（默认标签为第 N 页）。
  @override
  Future<BookmarkRow> addBookmark({String? label}) async {
    final bookmark = await _bookmarks.add(
      documentId: documentId,
      pageIndex: _pageIndex,
      label: label,
    );
    await refreshBookmarks();
    return bookmark;
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    await _bookmarks.remove(bookmarkId);
    await refreshBookmarks();
  }

  @override
  Future<void> jumpToTocEntry(TocEntryRow entry) async {
    final page = entry.pageIndex;
    if (page == null || page < 0) return;
    await goTo(page);
  }

  @override
  Future<void> jumpToBookmark(BookmarkRow bookmark) async {
    final page = bookmark.pageIndex;
    if (page == null || page < 0) return;
    await goTo(page);
  }

  @override
  bool isTocEntryCurrent(TocEntryRow entry) {
    String? current;
    for (final item in _tocItems) {
      final page = item.pageIndex;
      if (page == null || page < 0 || page > _pageIndex) continue;
      current = item.id;
    }
    return entry.id == current;
  }

  @override
  String tocEntryLocation(TocEntryRow entry) {
    final page = entry.pageIndex;
    return page == null || page < 0 ? '—' : '${page + 1}';
  }

  @override
  String bookmarkLocation(BookmarkRow bookmark) {
    final page = bookmark.pageIndex;
    return page == null ? '位置未知' : '第 ${page + 1} 页';
  }

  @override
  String? takeTransientMessage() => null;

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_saveProgress()),
    );
  }

  Future<void> _saveProgress() async {
    if (_pageCount == 0) return;
    await _progress.save(
      documentId: documentId,
      pageIndex: _pageIndex,
      offsetY: 0,
    );
  }

  /// 退出阅读页前调用，确保进度落库。
  @override
  Future<void> flushProgress() async {
    _saveTimer?.cancel();
    await _saveProgress();
  }

  void _clearImages() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    unawaited(_saveProgress());
    _clearImages();
    unawaited(_handle?.dispose() ?? Future<void>.value());
    super.dispose();
  }
}
