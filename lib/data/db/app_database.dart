import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/bookmarks_dao.dart';
import 'daos/documents_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/toc_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// 本地数据库。表结构变更必须提升 [schemaVersion] 并附迁移测试。
@DriftDatabase(
  tables: [Documents, ReadingProgress, Bookmarks, Highlights, TocEntries, AppMeta],
  daos: [DocumentsDao, ProgressDao, BookmarksDao, TocDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2：PDF 专用字段放宽为可空，并补 EPUB 的格式 / 位置 / href 字段。
            // TableMigration 会按当前表定义重建表并复制旧列，老 PDF 数据原样保留。
            await m.alterTable(
              TableMigration(
                documents,
                newColumns: [documents.format],
                columnTransformer: {
                  documents.format: const Constant('pdf'),
                },
              ),
            );
            await m.alterTable(
              TableMigration(
                readingProgress,
                newColumns: [readingProgress.position],
              ),
            );
            await m.alterTable(
              TableMigration(
                tocEntries,
                newColumns: [tocEntries.href, tocEntries.fragment],
              ),
            );
          }
          if (from < 3) {
            // v3：书签页码放宽为可空，并补 EPUB 的 position（0–1）。
            await m.alterTable(
              TableMigration(
                bookmarks,
                newColumns: [bookmarks.position],
              ),
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openDefault() => driftDatabase(name: 'home_pdf_reader');
}
