import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// 阅读进度仓库：单文档一条记录。
class ProgressRepository {
  ProgressRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  Future<ReadingProgressRow?> load(String documentId) => _db.progressDao.byDocument(documentId);

  /// 全部进度流，书架用来展示 EPUB 百分比。
  Stream<List<ReadingProgressRow>> watchAll() => _db.progressDao.watchAll();

  /// PDF 用 [pageIndex]，EPUB 用 [position]（0–1）；另一个传 null。
  Future<void> save({
    required String documentId,
    int? pageIndex,
    double? position,
    double offsetY = 0,
    double? zoom,
  }) =>
      _db.progressDao.upsert(
        ReadingProgressCompanion.insert(
          documentId: documentId,
          pageIndex: Value(pageIndex),
          position: Value(position),
          offsetY: Value(offsetY),
          zoom: Value(zoom),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
}
