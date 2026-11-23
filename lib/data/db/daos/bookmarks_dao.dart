import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'bookmarks_dao.g.dart';

@DriftAccessor(tables: [Bookmarks])
class BookmarksDao extends DatabaseAccessor<AppDatabase> with _$BookmarksDaoMixin {
  BookmarksDao(super.db);

  Future<List<BookmarkRow>> listByDocument(String documentId) => (select(bookmarks)
        ..where((t) => t.documentId.equals(documentId))
        ..orderBy([(t) => OrderingTerm.asc(t.pageIndex), (t) => OrderingTerm.asc(t.createdAt)]))
      .get();

  Future<void> insertBookmark(BookmarksCompanion entry) => into(bookmarks).insert(entry);

  Future<int> deleteById(String id) => (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<int> deleteAllOfDocument(String documentId) =>
      (delete(bookmarks)..where((t) => t.documentId.equals(documentId))).go();
}
