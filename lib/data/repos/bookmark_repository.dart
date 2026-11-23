import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// 书签仓库。M1 只做基础增删查，改名与去重规则留待 M4。
class BookmarkRepository {
  BookmarkRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<BookmarkRow>> list(String documentId) => _db.bookmarksDao.listByDocument(documentId);

  /// 新增书签：PDF 传 [pageIndex]，EPUB 传 [position]（0–1）。
  ///
  /// 默认标签分别取「第 N 页」与「位置 N%」。
  Future<BookmarkRow> add({
    required String documentId,
    int? pageIndex,
    double? position,
    double posY = 0,
    String? label,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final name = label ??
        (pageIndex != null
            ? '第 ${pageIndex + 1} 页'
            : '位置 ${((position ?? 0) * 100).round()}%');
    await _db.bookmarksDao.insertBookmark(
      BookmarksCompanion.insert(
        id: id,
        documentId: documentId,
        pageIndex: Value(pageIndex),
        position: Value(position),
        posY: posY,
        label: name,
        createdAt: createdAt,
      ),
    );
    return BookmarkRow(
      id: id,
      documentId: documentId,
      pageIndex: pageIndex,
      position: position,
      posY: posY,
      label: name,
      excerpt: null,
      createdAt: createdAt,
    );
  }

  Future<void> remove(String bookmarkId) => _db.bookmarksDao.deleteById(bookmarkId);

  Future<void> clear(String documentId) => _db.bookmarksDao.deleteAllOfDocument(documentId);
}
