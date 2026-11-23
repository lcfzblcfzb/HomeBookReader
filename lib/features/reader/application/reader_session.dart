import 'package:flutter/foundation.dart';

import '../../../data/db/app_database.dart';

/// 阅读面板内的页签。
///
/// 「排版」只在 EPUB 阅读页出现；PDF 不显示该页签。
enum ReaderPanelTab { bookmarks, toc, typography }

/// 阅读页外壳依赖的最小会话接口。
///
/// PDF 与 EPUB 各自实现：面板状态、书签、目录、翻页与进度保存都从这里来，
/// 外壳只负责沉浸式、侧边入口、面板动画与返回键。
abstract class ReaderSession extends ChangeNotifier {
  DocumentRow? get document;
  bool get loading;
  String? get errorMessage;

  bool get bookmarksVisible;
  ReaderPanelTab get panelTab;
  List<BookmarkRow> get bookmarkItems;
  List<TocEntryRow> get tocItems;
  bool get tocLoading;
  String? get tocError;

  /// 是否具备文字目录（EPUB 恒为 true）。
  bool get hasTextLayer;

  /// PDF 当前页码；EPUB 无页概念，返回 null。
  int? get currentPageIndex;

  /// EPUB 当前章节 href；PDF 返回 null。
  String? get currentHref;

  /// 是否显示「排版」页签。
  bool get supportsTypography;

  void openBookmarks();
  void closeBookmarks();
  void selectPanelTab(ReaderPanelTab tab);

  void nextPage();
  void previousPage();

  Future<void> jumpToTocEntry(TocEntryRow entry);
  Future<void> jumpToBookmark(BookmarkRow bookmark);

  Future<BookmarkRow> addBookmark({String? label});
  Future<void> removeBookmark(String bookmarkId);

  /// 退出阅读页前确保进度落库。
  Future<void> flushProgress();

  /// 目录条目是否为当前章节 / 页码。
  bool isTocEntryCurrent(TocEntryRow entry);

  /// 目录条目右侧的位置文字；EPUB 返回空串。
  String tocEntryLocation(TocEntryRow entry);

  /// 书签副标题，如「第 12 页」或「位置 34%」。
  String bookmarkLocation(BookmarkRow bookmark);

  /// 取一条一次性提示（如「已到全书末尾」），取走后清空。
  String? takeTransientMessage();
}
