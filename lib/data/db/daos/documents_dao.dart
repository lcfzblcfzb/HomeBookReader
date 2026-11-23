import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'documents_dao.g.dart';

@DriftAccessor(tables: [Documents])
class DocumentsDao extends DatabaseAccessor<AppDatabase> with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  /// 书架排序：最近打开优先，其次按导入时间倒序。
  Stream<List<DocumentRow>> watchAll() =>
      (select(documents)..orderBy([(t) => OrderingTerm.desc(t.lastOpenedAt), (t) => OrderingTerm.desc(t.addedAt)])).watch();

  Future<List<DocumentRow>> listAll() =>
      (select(documents)..orderBy([(t) => OrderingTerm.desc(t.lastOpenedAt), (t) => OrderingTerm.desc(t.addedAt)])).get();

  Future<DocumentRow?> byId(String id) =>
      (select(documents)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DocumentRow?> bySha256(String hash) =>
      (select(documents)..where((t) => t.sha256.equals(hash))).getSingleOrNull();

  Future<void> insertDocument(DocumentsCompanion entry) => into(documents).insert(entry);

  Future<void> touchOpened(String id, int openedAt) =>
      (update(documents)..where((t) => t.id.equals(id))).write(DocumentsCompanion(lastOpenedAt: Value(openedAt)));

  Future<int> deleteById(String id) => (delete(documents)..where((t) => t.id.equals(id))).go();
}
