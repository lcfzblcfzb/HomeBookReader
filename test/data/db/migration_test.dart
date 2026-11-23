import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('v1 旧库升级到 v3：PDF 数据保留，EPUB 字段与位置书签可写', () async {
    final temp = await Directory.systemTemp.createTemp('drift_migration_test_');
    addTearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });
    final file = File('${temp.path}${Platform.pathSeparator}library.db');
    await _createV1Database(file);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final documents = await db.documentsDao.listAll();
    expect(documents.length, 1);
    expect(documents.single.id, 'doc-1');
    expect(documents.single.format, 'pdf');
    expect(documents.single.pageCount, 12);

    final progress = await db.progressDao.byDocument('doc-1');
    expect(progress, isNotNull);
    expect(progress!.pageIndex, 3);
    expect(progress.position, isNull);

    final toc = await db.tocDao.listByDocument('doc-1');
    expect(toc.length, 1);
    expect(toc.single.pageIndex, 5);
    expect(toc.single.href, isNull);
    expect(toc.single.fragment, isNull);

    await db.documentsDao.insertDocument(
      DocumentsCompanion.insert(
        id: 'doc-2',
        sha256: 'hash-2',
        title: 'EPUB 之书',
        author: const Value('作者甲'),
        format: const Value('epub'),
        relPath: 'epubs/doc-2.epub',
        pageCount: const Value<int?>(null),
        fileSize: 2048,
        hasTextLayer: true,
        addedAt: 2,
      ),
    );
    await db.tocDao.replaceAll('doc-2', <TocEntriesCompanion>[
      TocEntriesCompanion.insert(
        id: 'toc-2',
        documentId: 'doc-2',
        title: '第一章',
        level: 1,
        pageIndex: const Value<int?>(null),
        href: const Value('text/ch1.xhtml'),
        fragment: const Value('sec1'),
        sortOrder: 0,
      ),
    ]);

    final epub = await db.documentsDao.byId('doc-2');
    expect(epub!.format, 'epub');
    expect(epub.pageCount, isNull);
    final epubToc = await db.tocDao.listByDocument('doc-2');
    expect(epubToc.single.href, 'text/ch1.xhtml');
    expect(epubToc.single.fragment, 'sec1');
    expect(epubToc.single.pageIndex, isNull);

    // v3：EPUB 书签不占页码字段，位置用 position（0–1）。
    await db.bookmarksDao.insertBookmark(
      BookmarksCompanion.insert(
        id: 'bm-epub',
        documentId: 'doc-2',
        pageIndex: const Value<int?>(null),
        position: const Value(0.42),
        posY: 0,
        label: '位置 42%',
        createdAt: 3,
      ),
    );
    final bookmark = (await db.bookmarksDao.listByDocument('doc-2')).single;
    expect(bookmark.pageIndex, isNull);
    expect(bookmark.position, 0.42);

    // 旧 PDF 书签的页码字段仍然可写。
    await db.bookmarksDao.insertBookmark(
      BookmarksCompanion.insert(
        id: 'bm-pdf',
        documentId: 'doc-1',
        pageIndex: const Value(3),
        posY: 0.5,
        label: '第 4 页',
        createdAt: 4,
      ),
    );
    final pdfBookmark = (await db.bookmarksDao.listByDocument('doc-1')).single;
    expect(pdfBookmark.pageIndex, 3);
    expect(pdfBookmark.position, isNull);
  });
}

/// 按 schemaVersion 1 时期的表结构造一份旧库，模拟真实升级。
Future<void> _createV1Database(File file) async {
  final db = sqlite3.open(file.path);
  try {
    db.execute('''
CREATE TABLE documents (
  id TEXT NOT NULL PRIMARY KEY,
  sha256 TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  author TEXT NULL,
  rel_path TEXT NOT NULL,
  cover_rel_path TEXT NULL,
  page_count INTEGER NOT NULL,
  file_size INTEGER NOT NULL,
  has_text_layer INTEGER NOT NULL,
  added_at INTEGER NOT NULL,
  last_opened_at INTEGER NULL
);
CREATE TABLE reading_progress (
  document_id TEXT NOT NULL PRIMARY KEY REFERENCES documents(id) ON DELETE CASCADE,
  page_index INTEGER NOT NULL,
  offset_y REAL NOT NULL DEFAULT 0,
  zoom REAL NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE bookmarks (
  id TEXT NOT NULL PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  page_index INTEGER NOT NULL,
  pos_y REAL NOT NULL,
  label TEXT NOT NULL,
  excerpt TEXT NULL,
  created_at INTEGER NOT NULL
);
CREATE TABLE highlights (
  id TEXT NOT NULL PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  page_index INTEGER NOT NULL,
  rects_json TEXT NOT NULL,
  text_snapshot TEXT NULL,
  note TEXT NULL,
  color INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE toc_entries (
  id TEXT NOT NULL PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  parent_id TEXT NULL,
  title TEXT NOT NULL,
  level INTEGER NOT NULL,
  page_index INTEGER NOT NULL,
  sort_order INTEGER NOT NULL
);
CREATE TABLE app_meta (
  key TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
);
''');
    db.execute(
      'INSERT INTO documents (id, sha256, title, rel_path, page_count, file_size, has_text_layer, added_at) '
      "VALUES ('doc-1', 'hash-1', '旧 PDF', 'pdfs/doc-1.pdf', 12, 1024, 1, 1)",
    );
    db.execute(
      'INSERT INTO reading_progress (document_id, page_index, offset_y, updated_at) '
      "VALUES ('doc-1', 3, 0.25, 1)",
    );
    db.execute(
      'INSERT INTO toc_entries (id, document_id, title, level, page_index, sort_order) '
      "VALUES ('toc-1', 'doc-1', '第一章', 1, 5, 0)",
    );
    db.execute('PRAGMA user_version = 1');
  } finally {
    db.close();
  }
}
