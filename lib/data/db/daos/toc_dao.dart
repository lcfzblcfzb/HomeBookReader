import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'toc_dao.g.dart';

@DriftAccessor(tables: [TocEntries, AppMeta])
class TocDao extends DatabaseAccessor<AppDatabase> with _$TocDaoMixin {
  TocDao(super.db);

  Future<List<TocEntryRow>> listByDocument(String documentId) => (select(tocEntries)
        ..where((t) => t.documentId.equals(documentId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();

  /// 是否已解析过（空目录也算已解析，避免每次打开重复解析）。
  Future<bool> isParsed(String documentId) async {
    final row = await (select(appMeta)
          ..where((t) => t.key.equals(_parsedKey(documentId))))
        .getSingleOrNull();
    return row?.value == '1';
  }

  /// 用一次解析结果整体替换缓存，并标记已解析。
  Future<void> replaceAll(
    String documentId,
    List<TocEntriesCompanion> entries,
  ) async {
    await transaction(() async {
      await (delete(tocEntries)..where((t) => t.documentId.equals(documentId)))
          .go();
      if (entries.isNotEmpty) {
        await batch((b) => b.insertAll(tocEntries, entries));
      }
      await into(appMeta).insertOnConflictUpdate(
        AppMetaCompanion.insert(key: _parsedKey(documentId), value: '1'),
      );
    });
  }

  String _parsedKey(String documentId) => 'toc_parsed:$documentId';
}
