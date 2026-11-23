import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' show Size;

import '../../../core/ebook/epub_content.dart';
import '../../../core/ebook/epub_session.dart';
import '../../../core/ebook/epub_typography.dart';
import '../../../core/storage/app_paths.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repos/bookmark_repository.dart';
import '../../../data/repos/document_repository.dart';
import '../../../data/repos/progress_repository.dart';
import '../../../data/repos/reader_typography_repository.dart';
import '../../../data/repos/toc_repository.dart';
import 'epub_paginator.dart';
import 'reader_session.dart';

/// EPUB 分页阅读控制器。
///
/// 启动只解析包与目录，正文按章懒解析；排版逐页推进，结果按章缓存。
/// 进度用 `position`（章节序号 + 章内字符比例）表示，与字号 / 屏幕无关。
class EpubReaderController extends ReaderSession {
  EpubReaderController({
    required DocumentRepository documents,
    required ProgressRepository progress,
    required BookmarkRepository bookmarks,
    required TocRepository toc,
    required ReaderTypographyRepository typography,
    required this.documentId,
  }) : _documents = documents,
       _progress = progress,
       _bookmarks = bookmarks,
       _toc = toc,
       _typographyRepository = typography;

  final DocumentRepository _documents;
  final ProgressRepository _progress;
  final BookmarkRepository _bookmarks;
  final TocRepository _toc;
  final ReaderTypographyRepository _typographyRepository;
  final String documentId;

  static const int _chapterCacheLimit = 3;
  static const int _imageCacheLimit = 6;
  static const int _endChar = 1 << 30;

  DocumentRow? _document;
  EpubSession? _session;
  EpubTypography _typography = const EpubTypography();
  final LinkedHashMap<int, _ChapterRuntime> _chapters =
      LinkedHashMap<int, _ChapterRuntime>();
  final Map<String, EpubImageInfo> _imageInfos = <String, EpubImageInfo>{};
  final LinkedHashMap<String, Uint8List> _imageBytes =
      LinkedHashMap<String, Uint8List>();

  double _contentWidth = 0;
  double _contentHeight = 0;
  int _chapterIndex = 0;
  int _pageInChapter = 0;
  int _currentChar = 0;
  double _pendingPosition = 0;
  bool _needsInitialRestore = true;
  bool _layouting = false;

  /// 正在定位到目标字符；定位完成前不渲染中途排出的页，避免闪回章首。
  bool _positioning = false;
  bool _disposed = false;
  int _moveToken = 0;

  bool _loading = true;
  String? _errorMessage;
  bool _bookmarksVisible = false;
  ReaderPanelTab _panelTab = ReaderPanelTab.bookmarks;
  List<BookmarkRow> _bookmarkItems = const <BookmarkRow>[];
  List<TocEntryRow> _tocItems = const <TocEntryRow>[];
  bool _tocLoading = false;
  String? _tocError;
  String? _transientMessage;
  Timer? _saveTimer;

  @override
  DocumentRow? get document => _document;

  @override
  bool get loading => _loading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  bool get bookmarksVisible => _bookmarksVisible;

  @override
  ReaderPanelTab get panelTab => _panelTab;

  @override
  List<BookmarkRow> get bookmarkItems => _bookmarkItems;

  @override
  List<TocEntryRow> get tocItems => _tocItems;

  @override
  bool get tocLoading => _tocLoading;

  @override
  String? get tocError => _tocError;

  @override
  bool get hasTextLayer => true;

  @override
  int? get currentPageIndex => null;

  @override
  String? get currentHref {
    final session = _session;
    if (session == null || session.spine.isEmpty) return null;
    return session.spine[_chapterIndex.clamp(0, session.chapterCount - 1)].href;
  }

  @override
  bool get supportsTypography => true;

  EpubTypography get typography => _typography;

  EpubSession? get session => _session;

  /// 当前章是否仍在排版（页面可能显示轻量加载态）。
  bool get layouting => _layouting;

  /// 当前页；尚未排出来（或正在定位）时为 null。
  EpubPage? get currentPage {
    if (_positioning) return null;
    final runtime = _chapters[_chapterIndex];
    if (runtime == null) return null;
    final pages = runtime.layout.pages;
    if (pages.isEmpty || _pageInChapter >= pages.length) return null;
    return pages[_pageInChapter];
  }

  /// 当前章解析 / 排版错误。
  String? get chapterError => _chapters[_chapterIndex]?.layout.error;

  /// 当前阅读位置（0–1），书架与进度都存这个值。
  double get position {
    final session = _session;
    if (session == null || session.chapterCount == 0) return 0;
    final runtime = _chapters[_chapterIndex];
    final charCount = runtime?.content?.charCount ?? runtime?.layout.charCount ?? 0;
    final intra = charCount <= 0
        ? 0.0
        : (_currentChar / charCount).clamp(0.0, 0.999999);
    return ((_chapterIndex + intra) / session.chapterCount).clamp(0.0, 1.0);
  }

  @override
  String? takeTransientMessage() {
    final message = _transientMessage;
    _transientMessage = null;
    return message;
  }

  /// 打开文档并恢复上次位置；排版等 [setViewport] 给出可用宽高后再开始。
  Future<void> open() async {
    try {
      final document = await _documents.byId(documentId);
      if (document == null) {
        _fail('文档不存在，可能已被删除');
        return;
      }
      _document = document;
      final file = AppPaths.resolve(document.relPath);
      if (!await file.exists()) {
        _fail('文件已丢失，请回到书架重新导入');
        return;
      }
      _session = await EpubSession.open(file);
      _typography = await _typographyRepository.load();
      final saved = await _progress.load(documentId);
      _pendingPosition = (saved?.position ?? 0).clamp(0.0, 1.0);
      _bookmarkItems = await _bookmarks.list(documentId);
      _loading = false;
      notifyListeners();
      unawaited(_loadToc());
      unawaited(_restoreInitial());
    } catch (error, stack) {
      AppLogger.log(
        '打开 EPUB 失败',
        level: 'ERROR',
        tag: 'EPUB',
        detail: '$error\n$stack',
      );
      _fail('打开 EPUB 失败：$error');
    }
  }

  void _fail(String message) {
    _errorMessage = message;
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadToc() async {
    _tocLoading = true;
    if (!_disposed) notifyListeners();
    try {
      _tocItems = await _toc.list(documentId);
      _tocError = null;
    } catch (error) {
      _tocError = '目录读取失败';
      AppLogger.log(
        'EPUB 目录读取失败',
        level: 'WARN',
        tag: 'EPUB',
        detail: '$error',
      );
    } finally {
      _tocLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// 阅读区宽高变化（首次布局、转屏、窗口尺寸变化）。
  void setViewport(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if ((size.width - _contentWidth).abs() < 0.5 &&
        (size.height - _contentHeight).abs() < 0.5) {
      return;
    }
    _contentWidth = size.width;
    _contentHeight = size.height;
    _invalidateLayouts();
    if (_needsInitialRestore) {
      unawaited(_restoreInitial());
    } else {
      unawaited(_showChapter(_chapterIndex, _currentChar));
    }
  }

  /// 切换字号 / 行距：整本重排，落回当前段。
  Future<void> setTypography(EpubTypography value) async {
    if (value == _typography) return;
    _typography = value;
    notifyListeners();
    _invalidateLayouts();
    unawaited(_typographyRepository.save(value));
    if (!_loading && _errorMessage == null) {
      await _showChapter(_chapterIndex, _currentChar);
    }
  }

  Future<void> _restoreInitial() async {
    if (!_needsInitialRestore ||
        _loading ||
        _errorMessage != null ||
        _session == null ||
        _contentWidth <= 0 ||
        _contentHeight <= 0) {
      return;
    }
    _needsInitialRestore = false;
    await _jumpToPosition(_pendingPosition);
  }

  Future<void> _jumpToPosition(double position) async {
    final session = _session;
    if (session == null || session.chapterCount == 0) return;
    final scaled = (position.clamp(0.0, 1.0) * session.chapterCount)
        .clamp(0.0, session.chapterCount - 0.000001);
    final chapter = scaled.floor().clamp(0, session.chapterCount - 1);
    var intra = scaled - chapter;
    if (intra >= 1) intra = 0.999999;

    final runtime = _runtimeFor(chapter);
    final content = await _contentFor(runtime);
    if (content == null) {
      // 该章解析失败：退回章首，至少能显示错误提示。
      await _showChapter(chapter, 0);
      return;
    }
    final char = (intra * content.charCount).round();
    await _showChapter(chapter, char);
  }

  /// 切到指定章节的指定字符位置；返回时页面已可显示。
  Future<void> _showChapter(int chapter, int charOffset) async {
    final session = _session;
    if (session == null || session.chapterCount == 0) return;
    final token = ++_moveToken;
    final index = chapter.clamp(0, session.chapterCount - 1);
    _chapterIndex = index;
    _currentChar = charOffset;
    _pageInChapter = 0;
    _positioning = true;
    _layouting = true;
    notifyListeners();

    final runtime = _runtimeFor(index);
    unawaited(_paginateOnce(runtime));
    await _waitForPages(runtime, (layout) => _hasPageFor(layout, charOffset));
    if (_disposed || token != _moveToken) return;

    final layout = runtime.layout;
    if (layout.error != null) {
      _positioning = false;
      _layouting = false;
      notifyListeners();
      return;
    }
    final pageIndex = layout.pageIndexForChar(charOffset);
    _pageInChapter = pageIndex;
    final charCount = runtime.content?.charCount ?? layout.charCount;
    if (charCount > 0) {
      _currentChar = charOffset.clamp(0, charCount - 1);
    }
    _positioning = false;
    _layouting = !layout.complete;
    _scheduleSave();
    notifyListeners();
  }

  _ChapterRuntime _runtimeFor(int index) {
    final cached = _chapters.remove(index);
    if (cached != null) {
      _chapters[index] = cached;
      return cached;
    }
    final runtime = _ChapterRuntime(index);
    _chapters[index] = runtime;
    _evictChapters();
    return runtime;
  }

  void _evictChapters() {
    while (_chapters.length > _chapterCacheLimit) {
      int? victim;
      for (final key in _chapters.keys) {
        if (key != _chapterIndex) {
          victim = key;
          break;
        }
      }
      if (victim == null) break;
      final runtime = _chapters.remove(victim);
      runtime?.cancel();
    }
  }

  void _invalidateLayouts() {
    _moveToken++;
    for (final runtime in _chapters.values) {
      runtime.cancel();
    }
    _chapters.clear();
    _pageInChapter = 0;
    _layouting = false;
  }

  Future<EpubChapterContent?> _contentFor(_ChapterRuntime runtime) async {
    if (runtime.content != null) return runtime.content;
    final pending = runtime.contentFuture;
    if (pending != null) return pending;
    final future = Future<EpubChapterContent?>(() {
      final session = _session;
      if (session == null) return null;
      final html = session.readChapter(runtime.index);
      if (html == null) {
        throw const EpubContentException('本章文件缺失');
      }
      return EpubContentParser.parse(
        html,
        chapterHref: session.spine[runtime.index].href,
      );
    }).then((content) {
      runtime.content = content;
      return content;
    }).catchError((Object error) {
      runtime.layout.error = error is EpubContentException
          ? error.reason
          : '本章内容解析失败';
      runtime.layout.complete = true;
      _signalPage(runtime);
      AppLogger.log(
        'EPUB 章节解析失败',
        level: 'WARN',
        tag: 'EPUB',
        detail: 'chapter=${runtime.index} $error',
      );
      return null;
    });
    runtime.contentFuture = future;
    return future;
  }

  Future<void> _paginateOnce(_ChapterRuntime runtime) async {
    if (runtime.started) return;
    runtime.started = true;
    final content = await _contentFor(runtime);
    if (_disposed || runtime.cancelled || content == null) {
      runtime.layout.complete = true;
      _signalPage(runtime);
      return;
    }
    final layout = runtime.layout;
    layout
      ..chapterIndex = runtime.index
      ..charCount = content.charCount
      ..pages.clear()
      ..complete = false
      ..error = null;

    final paginator = EpubPaginator(
      content: content,
      chapterIndex: runtime.index,
      typography: _typography,
      contentWidth: _contentWidth,
      contentHeight: _contentHeight,
      layout: layout,
      loadImage: _loadImageInfo,
      onPage: () => _signalPage(runtime),
      isCancelled: () => _disposed || runtime.cancelled,
    );
    try {
      await paginator.paginate();
    } catch (error) {
      layout.error = '本章排版失败';
      layout.complete = true;
      AppLogger.log(
        'EPUB 排版失败',
        level: 'WARN',
        tag: 'EPUB',
        detail: 'chapter=${runtime.index} $error',
      );
    }
    _signalPage(runtime);
    if (!_disposed && runtime.index == _chapterIndex) {
      _layouting = false;
      notifyListeners();
    }
  }

  bool _hasPageFor(EpubChapterLayout layout, int charOffset) {
    if (layout.pages.isEmpty) return layout.complete;
    return layout.complete || layout.pages.last.startChar > charOffset;
  }

  Future<void> _waitForPages(
    _ChapterRuntime runtime,
    bool Function(EpubChapterLayout layout) ready,
  ) async {
    while (!_disposed && !runtime.cancelled) {
      if (ready(runtime.layout) || runtime.layout.complete) return;
      await runtime.signal.future;
    }
  }

  void _signalPage(_ChapterRuntime runtime) {
    if (!runtime.signal.isCompleted) {
      runtime.signal.complete();
    }
    runtime.signal = Completer<void>();
    if (!_disposed && runtime.index == _chapterIndex) {
      _layouting = !runtime.layout.complete;
      notifyListeners();
    }
  }

  @override
  void nextPage() {
    unawaited(_nextPage());
  }

  Future<void> _nextPage() async {
    final session = _session;
    if (session == null) return;
    final token = ++_moveToken;
    final runtime = _runtimeFor(_chapterIndex);
    unawaited(_paginateOnce(runtime));
    await _waitForPages(runtime, (layout) => layout.pages.isNotEmpty);
    if (_disposed || token != _moveToken || runtime.layout.error != null) return;

    if (_pageInChapter + 1 < runtime.layout.pages.length) {
      _setPage(_pageInChapter + 1);
      return;
    }
    if (!runtime.layout.complete) {
      await _waitForPages(
        runtime,
        (layout) =>
            layout.complete || layout.pages.length > _pageInChapter + 1,
      );
      if (_disposed || token != _moveToken) return;
    }
    if (_pageInChapter + 1 < runtime.layout.pages.length) {
      _setPage(_pageInChapter + 1);
      return;
    }
    if (_chapterIndex + 1 >= session.chapterCount) {
      _transientMessage = '已到全书末尾';
      notifyListeners();
      return;
    }
    await _showChapter(_chapterIndex + 1, 0);
  }

  @override
  void previousPage() {
    unawaited(_previousPage());
  }

  Future<void> _previousPage() async {
    final session = _session;
    if (session == null) return;
    final token = ++_moveToken;
    final runtime = _runtimeFor(_chapterIndex);
    unawaited(_paginateOnce(runtime));
    await _waitForPages(runtime, (layout) => layout.pages.isNotEmpty);
    if (_disposed || token != _moveToken) return;

    if (_pageInChapter > 0) {
      _setPage(_pageInChapter - 1);
      return;
    }
    if (_chapterIndex == 0) return;
    await _showChapter(_chapterIndex - 1, _endChar);
  }

  void _setPage(int index) {
    final runtime = _chapters[_chapterIndex];
    if (runtime == null) return;
    final pages = runtime.layout.pages;
    if (index < 0 || index >= pages.length) return;
    _pageInChapter = index;
    _currentChar = pages[index].startChar;
    _scheduleSave();
    notifyListeners();
  }

  @override
  Future<void> jumpToTocEntry(TocEntryRow entry) async {
    final session = _session;
    final href = entry.href;
    if (session == null || href == null || href.isEmpty) {
      _showMessage('该目录项无法定位');
      return;
    }
    final index = session.spineIndexForHref(href);
    if (index == null) {
      _showMessage('该目录项不在正文中');
      return;
    }
    final runtime = _runtimeFor(index);
    final content = await _contentFor(runtime);
    if (content == null) {
      _showMessage('该目录项所在章节解析失败');
      return;
    }
    final char = content.offsetOfFragment(entry.fragment);
    await _showChapter(index, char);
  }

  @override
  Future<void> jumpToBookmark(BookmarkRow bookmark) async {
    final position = bookmark.position;
    if (position == null) return;
    await _jumpToPosition(position);
  }

  @override
  Future<BookmarkRow> addBookmark({String? label}) async {
    final position = this.position;
    final bookmark = await _bookmarks.add(
      documentId: documentId,
      position: position,
      label: label ?? '位置 ${(position * 100).round()}%',
    );
    await refreshBookmarks();
    return bookmark;
  }

  Future<void> refreshBookmarks() async {
    _bookmarkItems = await _bookmarks.list(documentId);
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    await _bookmarks.remove(bookmarkId);
    await refreshBookmarks();
  }

  @override
  void openBookmarks() {
    if (_bookmarksVisible) return;
    _bookmarksVisible = true;
    notifyListeners();
  }

  @override
  void closeBookmarks() {
    if (!_bookmarksVisible) return;
    _bookmarksVisible = false;
    notifyListeners();
  }

  @override
  void selectPanelTab(ReaderPanelTab tab) {
    if (_panelTab == tab) return;
    _panelTab = tab;
    notifyListeners();
  }

  @override
  bool isTocEntryCurrent(TocEntryRow entry) {
    final session = _session;
    final href = entry.href;
    if (session == null || href == null) return false;
    TocEntryRow? current;
    for (final item in _tocItems) {
      final itemHref = item.href;
      if (itemHref == null) continue;
      final index = session.spineIndexForHref(itemHref);
      if (index == null || index > _chapterIndex) continue;
      current = item;
    }
    return current?.id == entry.id;
  }

  @override
  String tocEntryLocation(TocEntryRow entry) => '';

  @override
  String bookmarkLocation(BookmarkRow bookmark) {
    final position = bookmark.position;
    if (position == null) return '位置未知';
    return '位置 ${(position * 100).round()}%';
  }

  void _showMessage(String message) {
    _transientMessage = message;
    notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_saveProgress()),
    );
  }

  Future<void> _saveProgress() async {
    if (_session == null) return;
    try {
      await _progress.save(
        documentId: documentId,
        position: position,
        offsetY: 0,
      );
    } catch (error) {
      AppLogger.log(
        'EPUB 进度保存失败',
        level: 'WARN',
        tag: 'EPUB',
        detail: '$error',
      );
    }
  }

  @override
  Future<void> flushProgress() async {
    _saveTimer?.cancel();
    await _saveProgress();
  }

  /// 页面渲染图片时按 href 取字节；带小容量缓存，避免每帧解压。
  Uint8List? imageBytes(String href) {
    final cached = _imageBytes.remove(href);
    if (cached != null) {
      _imageBytes[href] = cached;
      return cached;
    }
    final bytes = _session?.readResource(href);
    if (bytes == null) return null;
    _imageBytes[href] = bytes;
    while (_imageBytes.length > _imageCacheLimit) {
      _imageBytes.remove(_imageBytes.keys.first);
    }
    return bytes;
  }

  Future<EpubImageInfo?> _loadImageInfo(String href) async {
    final cached = _imageInfos[href];
    if (cached != null) return cached;
    final bytes = imageBytes(href);
    if (bytes == null) return null;
    final info = await decodeEpubImage(bytes);
    if (info != null) _imageInfos[href] = info;
    return info;
  }

  @override
  void dispose() {
    if (_disposed) return;
    // 位置依赖当前章缓存，必须在清空之前取值保存。
    unawaited(_saveProgress());
    _disposed = true;
    _saveTimer?.cancel();
    for (final runtime in _chapters.values) {
      runtime.cancel();
    }
    _chapters.clear();
    super.dispose();
  }
}

/// 单章的解析 / 排版运行态。
class _ChapterRuntime {
  _ChapterRuntime(this.index);

  final int index;
  final EpubChapterLayout layout = EpubChapterLayout(
    chapterIndex: 0,
    charCount: 0,
  );
  EpubChapterContent? content;
  Future<EpubChapterContent?>? contentFuture;
  bool started = false;
  bool cancelled = false;
  Completer<void> signal = Completer<void>();

  void cancel() {
    cancelled = true;
    if (!signal.isCompleted) signal.complete();
  }
}
