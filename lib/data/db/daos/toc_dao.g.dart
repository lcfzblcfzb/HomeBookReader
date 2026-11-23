// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toc_dao.dart';

// ignore_for_file: type=lint
mixin _$TocDaoMixin on DatabaseAccessor<AppDatabase> {
  $DocumentsTable get documents => attachedDatabase.documents;
  $TocEntriesTable get tocEntries => attachedDatabase.tocEntries;
  $AppMetaTable get appMeta => attachedDatabase.appMeta;
  TocDaoManager get managers => TocDaoManager(this);
}

class TocDaoManager {
  final _$TocDaoMixin _db;
  TocDaoManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db.attachedDatabase, _db.documents);
  $$TocEntriesTableTableManager get tocEntries =>
      $$TocEntriesTableTableManager(_db.attachedDatabase, _db.tocEntries);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db.attachedDatabase, _db.appMeta);
}
