import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_pdf_reader/core/pdf/pdfrx_engine.dart';
import 'package:home_pdf_reader/core/storage/app_paths.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/bookmark_repository.dart';
import 'package:home_pdf_reader/data/repos/document_repository.dart';
import 'package:home_pdf_reader/data/repos/progress_repository.dart';
import 'package:home_pdf_reader/data/repos/toc_repository.dart';
import 'package:home_pdf_reader/features/reader/application/reader_controller.dart';

/// M1 Windows 端到端冒烟：真实 PDFium + 真实 SQLite（内存库）。
///
/// 运行：flutter test integration_test/m1_smoke_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M1 冒烟：导入 → 阅读 → 进度 → 书签 → 删除', (tester) async {
    await AppPaths.init();
    final db = AppDatabase(NativeDatabase.memory());
    const engine = PdfrxEngine();
    final documents = DocumentRepository(database: db, engine: engine);
    final progress = ProgressRepository(database: db);
    final bookmarks = BookmarkRepository(database: db);
    final toc = TocRepository(database: db);

    final source = File('test_assets/sample_text_zh.pdf');
    expect(source.existsSync(), isTrue, reason: '样本缺失：test_assets/sample_text_zh.pdf');

    // 导入
    final first = await documents.importFile(source);
    expect(first, isA<ImportSuccess>());
    final doc = (first as ImportSuccess).document;
    expect(doc.pageCount, 10);
    expect(doc.hasTextLayer, isTrue);
    expect(AppPaths.resolve(doc.relPath).existsSync(), isTrue);
    expect(doc.coverRelPath, isNotNull);

    // 去重与损坏文件
    expect(await documents.importFile(source), isA<ImportDuplicate>());
    expect(await documents.importFile(File('test_assets/sample_broken.pdf')), isA<ImportInvalid>());

    // 阅读
    final reader = ReaderController(
      documents: documents,
      progress: progress,
      bookmarks: bookmarks,
      toc: toc,
      documentId: doc.id,
    );
    await reader.load();
    expect(reader.errorMessage, isNull);
    expect(reader.pageCount, 10);
    expect(reader.pageIndex, 0);

    // 目录：后台解析完成后应能从缓存读出，页码均在文档范围内。
    for (var i = 0; i < 100 && reader.tocLoading; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(reader.tocItems, isNotEmpty);
    expect(
      reader.tocItems.every(
        (e) => (e.pageIndex ?? -1) >= 0 && (e.pageIndex ?? -1) < (doc.pageCount ?? 0),
      ),
      isTrue,
    );

    final image = await reader.imageFor(0, 600);
    expect(image, isNotNull);
    expect(image!.width, 600);

    // 翻页边界
    reader.previousPage();
    expect(reader.pageIndex, 0);
    expect(reader.hasPrevious, isFalse);

    reader.nextPage();
    reader.nextPage();
    await tester.pump(const Duration(milliseconds: 50));
    expect(reader.pageIndex, 2);
    reader.previousPage();
    await tester.pump(const Duration(milliseconds: 50));
    expect(reader.pageIndex, 1);

    // 书签
    await reader.addBookmark();
    expect(reader.bookmarkItems.length, 1);
    final bookmark = reader.bookmarkItems.single;
    expect(bookmark.pageIndex, 1);
    await reader.removeBookmark(bookmark.id);
    expect(reader.bookmarkItems, isEmpty);
    await reader.addBookmark();

    // 进度落库 + 恢复
    await reader.goTo(5);
    await reader.flushProgress();
    reader.dispose();

    final restored = ReaderController(
      documents: documents,
      progress: progress,
      bookmarks: bookmarks,
      toc: toc,
      documentId: doc.id,
    );
    await restored.load();
    expect(restored.pageIndex, 5);
    expect(restored.bookmarkItems.length, 1);
    restored.dispose();

    // 删除（DB 级联 + 文件）
    final relPath = doc.relPath;
    await documents.delete(doc.id);
    expect(await documents.list(), isEmpty);
    expect(AppPaths.resolve(relPath).existsSync(), isFalse);

    await db.close();
  });
}
