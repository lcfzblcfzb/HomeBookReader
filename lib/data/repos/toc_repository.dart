import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../core/pdf/outline_flatten.dart';
import '../../core/pdf/pdf_models.dart';
import '../../core/utils/app_logger.dart';
import '../db/app_database.dart';

/// 目录仓库：outline 解析结果缓存到 `toc_entries`，二次打开直接读库。
class TocRepository {
  TocRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<List<TocEntryRow>> list(String documentId) =>
      _db.tocDao.listByDocument(documentId);

  /// 取目录：已解析过直接读缓存，否则调用 [readOutline] 解析并落库。
  ///
  /// 空目录同样会被标记为已解析，避免每次打开都重复解析扫描件。
  Future<List<TocEntryRow>> loadOrParse({
    required String documentId,
    required Future<List<PdfOutlineNode>> Function() readOutline,
  }) async {
    if (await _db.tocDao.isParsed(documentId)) {
      return list(documentId);
    }
    final nodes = await readOutline();
    final flat = flattenOutline(nodes);
    final ids = <String>[];
    final entries = <TocEntriesCompanion>[];
    for (final node in flat) {
      final id = _uuid.v4();
      ids.add(id);
      entries.add(
        TocEntriesCompanion.insert(
          id: id,
          documentId: documentId,
          parentId: Value(
            node.parentIndex == null ? null : ids[node.parentIndex!],
          ),
          title: node.title,
          level: node.level,
          pageIndex: Value(node.pageIndex),
          sortOrder: node.sortOrder,
        ),
      );
    }
    await _db.tocDao.replaceAll(documentId, entries);
    AppLogger.log(
      '目录解析完成',
      tag: 'TOC',
      detail: 'document=$documentId entries=${entries.length}',
    );
    return list(documentId);
  }
}
