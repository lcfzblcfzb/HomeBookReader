import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/epub_typography.dart';
import 'package:home_pdf_reader/core/pdf/pdf_engine.dart';
import 'package:home_pdf_reader/core/storage/app_paths.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/bookmark_repository.dart';
import 'package:home_pdf_reader/data/repos/document_repository.dart';
import 'package:home_pdf_reader/data/repos/progress_repository.dart';
import 'package:home_pdf_reader/data/repos/reader_typography_repository.dart';
import 'package:home_pdf_reader/data/repos/toc_repository.dart';
import 'package:home_pdf_reader/features/reader/application/epub_paginator.dart';
import 'package:home_pdf_reader/features/reader/application/epub_reader_controller.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  // TextPainter 需要 binding 提供字体与渲染环境。
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late AppDatabase db;
  late DocumentRepository documents;
  late ProgressRepository progress;
  late BookmarkRepository bookmarks;
  late TocRepository toc;
  late ReaderTypographyRepository typography;
  late DocumentRow document;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('epub_reader_test_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await AppPaths.init();
    db = AppDatabase(NativeDatabase.memory());
    documents = DocumentRepository(database: db, engine: _UnusedPdfEngine());
    progress = ProgressRepository(database: db);
    bookmarks = BookmarkRepository(database: db);
    toc = TocRepository(database: db);
    typography = ReaderTypographyRepository(database: db);

    final source = File('${temp.path}${Platform.pathSeparator}reader.epub');
    await source.writeAsBytes(_buildEpub());
    final outcome = await documents.importFile(source);
    document = (outcome as ImportSuccess).document;
  });

  tearDown(() async {
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  EpubReaderController createController() => EpubReaderController(
    documents: documents,
    progress: progress,
    bookmarks: bookmarks,
    toc: toc,
    typography: typography,
    documentId: document.id,
  );

  test('翻页读通、跨章、末尾提示、目录跳转、退出重进回原处', () async {
    final controller = createController();
    addTearDown(controller.dispose);
    await controller.open();
    controller.setViewport(const Size(320, 440));
    await _settle(controller);

    expect(controller.errorMessage, isNull);
    final first = _pageText(controller);
    expect(first, contains('第一章'));
    expect(controller.currentHref, endsWith('ch1.xhtml'));

    // 右侧点击翻页：页内容与位置都前进。
    final positionBefore = controller.position;
    expect(await _nextPage(controller), isTrue);
    expect(controller.position, greaterThan(positionBefore));
    expect(_pageText(controller), isNot(first));

    // 连续翻页跨章：第 1 → 2 → 3 章。
    final hrefs = <String>{controller.currentHref!};
    for (var i = 0; i < 60 && hrefs.length < 3; i++) {
      await _nextPage(controller);
      hrefs.add(controller.currentHref!);
    }
    expect(hrefs.length, 3, reason: '应能跨章节连续翻页');

    // 目录跳转到「第三节」的 href + fragment。
    final entries = await toc.list(document.id);
    final section = entries.firstWhere((entry) => entry.title == '第三节');
    await controller.jumpToTocEntry(section);
    await _settle(controller);
    expect(controller.currentHref, endsWith('ch3.xhtml'));
    expect(_pageText(controller), contains('第三节'));

    // 在当前页加书签，跳到第一章后再跳回书签。
    final bookmark = await controller.addBookmark();
    final bookmarkPosition = controller.position;
    expect(bookmark.position, closeTo(bookmarkPosition, 1e-9));
    await controller.jumpToTocEntry(entries.first);
    await _settle(controller);
    expect(controller.currentHref, endsWith('ch1.xhtml'));
    await controller.jumpToBookmark(bookmark);
    await _settle(controller);
    expect(controller.position, closeTo(bookmarkPosition, 0.01));

    // 退出前落库，重进恢复到同一处。
    await controller.flushProgress();
    final pageTextBeforeExit = _pageText(controller);
    controller.dispose();

    final reopened = createController();
    addTearDown(reopened.dispose);
    await reopened.open();
    reopened.setViewport(const Size(320, 440));
    await _settle(reopened);
    expect(reopened.position, closeTo(bookmarkPosition, 0.01));
    expect(_markerOf(_pageText(reopened)), _markerOf(pageTextBeforeExit));

    // 一直翻到全书末尾给出提示。
    var sawEnd = false;
    for (var i = 0; i < 200 && !sawEnd; i++) {
      sawEnd = !await _nextPage(reopened);
    }
    expect(sawEnd, isTrue, reason: '翻到全书末尾应有明确提示');
  });

  test('改字号与横竖屏切换都落回同一段文字', () async {
    final controller = createController();
    addTearDown(controller.dispose);
    await controller.open();
    controller.setViewport(const Size(320, 440));
    await _settle(controller);

    // 翻到中段，记录当前位置的文字标记。
    for (var i = 0; i < 6; i++) {
      await _nextPage(controller);
    }
    final marker = _markerOf(_pageText(controller));
    expect(marker.length, greaterThan(4));
    final position = controller.position;

    // 字号最大 + 行距宽松：整本重排后仍停在原段。
    await controller.setTypography(
      const EpubTypography(fontLevel: 4, lineSpacingLevel: 1),
    );
    await _settle(controller);
    expect(controller.typography.fontSize, EpubTypography.fontSizes.last);
    expect(controller.position, closeTo(position, 0.01));
    expect(_pageText(controller), contains(marker));

    // 横屏（宽度变大、高度变小）后仍停在原段。
    controller.setViewport(const Size(640, 300));
    await _settle(controller);
    expect(controller.position, closeTo(position, 0.01));
    expect(_pageText(controller), contains(marker));

    // 竖屏来回切也不丢位置。
    controller.setViewport(const Size(320, 440));
    await _settle(controller);
    expect(controller.position, closeTo(position, 0.01));
    expect(_pageText(controller), contains(marker));
  });
}

Future<void> _settle(EpubReaderController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    if (controller.errorMessage != null) {
      fail('阅读页报错：${controller.errorMessage}');
    }
    if (controller.currentPage != null && !controller.layouting) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail(
    '等待排版超时：page=${controller.currentPage != null} '
    'layouting=${controller.layouting} chapter=${controller.currentHref}',
  );
}

/// 翻下一页并等到页面 / 章节变化；到全书末尾返回 false。
Future<bool> _nextPage(EpubReaderController controller) async {
  final position = controller.position;
  final href = controller.currentHref;
  controller.nextPage();
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final message = controller.takeTransientMessage();
    if (message != null) {
      expect(message, contains('末尾'));
      return false;
    }
    if (controller.position != position || controller.currentHref != href) {
      return true;
    }
    if (controller.errorMessage != null) {
      fail('翻页报错：${controller.errorMessage}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('翻页超时');
}

String _pageText(EpubReaderController controller) {
  final page = controller.currentPage;
  if (page == null) return '';
  final buffer = StringBuffer();
  for (final item in page.items) {
    switch (item) {
      case EpubTextItem():
        buffer.write(item.runs.map((run) => run.text).join());
      case EpubImageItem():
        buffer.write('[图片]');
      case EpubDividerItem():
        buffer.write('—');
    }
  }
  return buffer.toString();
}

/// 取页面开头一小段无声调标记，用于跨字号 / 转屏比对同一段文字。
String _markerOf(String text) {
  final compact = text.replaceAll(RegExp(r'[\s\u3000]+'), '');
  return compact.substring(0, math.min(8, compact.length)).replaceAll('—', '');
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _UnusedPdfEngine implements PdfEngine {
  @override
  Future<PdfDocumentHandle> open(String absolutePath) =>
      throw UnsupportedError('本测试不打开 PDF');
}

/// 构造一本最小可读 EPUB：3 章、长正文、目录 fragment、图片与基本样式。
List<int> _buildEpub() {
  final archive = Archive();
  void add(String name, String content) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  }

  void addBytes(String name, List<int> bytes) {
    archive.addFile(ArchiveFile.bytes(name, bytes));
  }

  archive.addFile(
    ArchiveFile.bytes('mimetype', utf8.encode('application/epub+zip')),
  );
  add('META-INF/container.xml', '''
<?xml version="1.0" encoding="utf-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>
''');
  add('OEBPS/content.opf', '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>分页验证书</dc:title>
    <dc:creator>测试作者</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch3" href="text/ch3.xhtml" media-type="application/xhtml+xml"/>
    <item id="pic" href="images/pic.png" media-type="image/png"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
    <itemref idref="ch3"/>
  </spine>
</package>
''');
  add('OEBPS/nav.xhtml', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="text/ch1.xhtml#c1">第一章</a></li>
    <li><a href="text/ch2.xhtml">第二章</a></li>
    <li><a href="text/ch3.xhtml#sec3">第三节</a></li>
  </ol></nav></body>
</html>
''');

  final filler = List<String>.filled(
    3,
    '这是用来占满页面并检验分页与位置恢复的正文内容，',
  ).join();
  String paragraphs(String prefix, int count) {
    final buffer = StringBuffer();
    for (var i = 0; i < count; i++) {
      buffer.write('<p>$prefix第${i + 1}段。$filler</p>');
    }
    return buffer.toString();
  }

  add('OEBPS/text/ch1.xhtml', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body>
  <h1 id="c1">第一章 起点</h1>
  ${paragraphs('第一章', 4)}
  <blockquote><p>第一章引用的一句话，用来验证引用样式能正常装页。</p></blockquote>
  <ul><li>第一章要点一</li><li>第一章要点二</li></ul>
</body></html>
''');
  add('OEBPS/text/ch2.xhtml', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body>
  <h1>第二章 中途</h1>
  ${paragraphs('第二章', 5)}
  <p><img src="../images/pic.png" alt="插图"/></p>
  <p><strong>第二章加粗</strong>与<em>第二章斜体</em>混排。</p>
</body></html>
''');
  add('OEBPS/text/ch3.xhtml', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body>
  <h1>第三章 归处</h1>
  ${paragraphs('第三章', 4)}
  <h2 id="sec3">第三节 深处</h2>
  ${paragraphs('第三节', 4)}
  <hr/>
</body></html>
''');
  addBytes(
    'OEBPS/images/pic.png',
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
  );
  return ZipEncoder().encode(archive);
}
