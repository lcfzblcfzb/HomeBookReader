import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/pdf/pdfrx_engine.dart';
import 'package:home_pdf_reader/core/storage/app_paths.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/bookmark_repository.dart';
import 'package:home_pdf_reader/data/repos/document_repository.dart';
import 'package:home_pdf_reader/data/repos/progress_repository.dart';
import 'package:home_pdf_reader/data/repos/toc_repository.dart';
import 'package:home_pdf_reader/features/reader/application/reader_controller.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// 阅读进度自动记录（PDF）：翻页节流落库、退出 flush、重进恢复到原页。
///
/// EPUB 侧「退出重进回原处」已在 epub_reader_controller_test.dart 覆盖，
/// 这里补 PDF 的同款断言，用真实 PDFium + 内存库跑完整循环。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late AppDatabase db;
  late DocumentRepository documents;
  late ProgressRepository progress;
  late DocumentRow document;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('reader_progress_test_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await AppPaths.init();
    db = AppDatabase(NativeDatabase.memory());
    documents = DocumentRepository(database: db, engine: const PdfrxEngine());
    progress = ProgressRepository(database: db);

    final source = File('test_assets/sample_text_zh.pdf');
    expect(source.existsSync(), isTrue, reason: '样本缺失：test_assets/sample_text_zh.pdf');
    final outcome = await documents.importFile(source);
    expect(outcome, isA<ImportSuccess>());
    document = (outcome as ImportSuccess).document;
  });

  tearDown(() async {
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  ReaderController createController() => ReaderController(
    documents: documents,
    progress: progress,
    bookmarks: BookmarkRepository(database: db),
    toc: TocRepository(database: db),
    documentId: document.id,
  );

  test('翻页 → 节流落库；退出 flush；重进恢复到原页', () async {
    // 第一次打开：翻到第 5 页（0 基 4），退出。
    final first = createController();
    await first.load();
    expect(first.pageIndex, 0, reason: '首次打开应从第 1 页开始');
    expect(first.pageCount, 10);

    await first.goTo(4);
    // 节流窗口（500ms）内库中可能还没有记录 —— 退出时 flushProgress 兜底。
    first.dispose();

    final second = createController();
    await second.load();
    expect(second.pageIndex, 4, reason: '重进应恢复到上次阅读页（第 5 页）');

    // 等节流窗口过后直接读库，确认自动落库路径（不依赖 dispose）。
    second.goTo(7);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final saved = await progress.load(document.id);
    expect(saved?.pageIndex, 7, reason: '翻页后 500ms 节流应自动落库');
    second.dispose();
  });

  test('越界进度（文档页数变化）clamp 到有效范围，不崩溃', () async {
    await progress.save(documentId: document.id, pageIndex: 99);
    final controller = createController();
    await controller.load();
    expect(controller.errorMessage, isNull);
    expect(controller.pageIndex, 9, reason: '超出页数的旧进度应落到最后一页');
    controller.dispose();
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
