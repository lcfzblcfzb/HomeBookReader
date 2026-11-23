import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'progress_dao.g.dart';

@DriftAccessor(tables: [ReadingProgress])
class ProgressDao extends DatabaseAccessor<AppDatabase> with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<ReadingProgressRow?> byDocument(String documentId) =>
      (select(readingProgress)..where((t) => t.documentId.equals(documentId))).getSingleOrNull();

  /// 全部进度；书架用它给 EPUB 显示百分比。
  Stream<List<ReadingProgressRow>> watchAll() => select(readingProgress).watch();

  Future<void> upsert(ReadingProgressCompanion entry) => into(readingProgress).insertOnConflictUpdate(entry);
}
