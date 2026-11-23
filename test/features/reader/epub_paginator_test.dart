import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/epub_content.dart';
import 'package:home_pdf_reader/core/ebook/epub_typography.dart';
import 'package:home_pdf_reader/features/reader/application/epub_paginator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('长段落按可用高度切页，页起始字符单调递增', () async {
    final paragraph = '这是一段用于分页测试的长文字。' * 120;
    final content = _content(<EpubBlock>[
      const EpubBlock(
        kind: EpubBlockKind.heading1,
        startChar: 0,
        runs: <EpubTextRun>[EpubTextRun('第一章')],
      ),
      EpubBlock(
        kind: EpubBlockKind.paragraph,
        startChar: 3,
        runs: <EpubTextRun>[EpubTextRun(paragraph)],
      ),
    ]);

    final paginator = EpubPaginator(
      content: content,
      chapterIndex: 2,
      typography: const EpubTypography(),
      contentWidth: 300,
      contentHeight: 220,
      loadImage: (href) async => null,
    );
    final layout = await paginator.paginate();

    expect(layout.complete, isTrue);
    expect(layout.chapterIndex, 2);
    expect(layout.pages.length, greaterThan(2));
    expect(layout.pages.first.startChar, 0);
    for (var i = 1; i < layout.pages.length; i++) {
      expect(layout.pages[i].startChar, greaterThanOrEqualTo(layout.pages[i - 1].startChar));
    }
    for (final page in layout.pages) {
      expect(page.items, isNotEmpty);
      expect(page.items.first.spacingBefore, 0);
    }
    expect(layout.pageIndexForChar(0), 0);
    final last = layout.pages.last;
    expect(layout.pageIndexForChar(last.startChar), layout.pages.length - 1);
  });

  test('段落跨页时续页从行边界开始，不重复段首缩进', () async {
    final paragraph = '天地玄黄宇宙洪荒。' * 200;
    final content = _content(<EpubBlock>[
      EpubBlock(
        kind: EpubBlockKind.paragraph,
        startChar: 0,
        runs: <EpubTextRun>[EpubTextRun(paragraph)],
      ),
    ]);

    final paginator = EpubPaginator(
      content: content,
      chapterIndex: 0,
      typography: const EpubTypography(),
      contentWidth: 280,
      contentHeight: 180,
      loadImage: (href) async => null,
    );
    final layout = await paginator.paginate();

    expect(layout.pages.length, greaterThan(2));
    final firstPageText = layout.pages.first.items
        .whereType<EpubTextItem>()
        .map((item) => item.runs.map((run) => run.text).join())
        .join();
    expect(firstPageText.startsWith('\u3000\u3000'), isTrue);
    for (final page in layout.pages.skip(1)) {
      final text = page.items
          .whereType<EpubTextItem>()
          .map((item) => item.runs.map((run) => run.text).join())
          .join();
      expect(text.startsWith('\u3000\u3000'), isFalse);
      expect(page.startChar, greaterThan(0));
    }
  });

  test('图片按原始宽高比等比缩放并居中占位', () async {
    final content = _content(<EpubBlock>[
      const EpubBlock(
        kind: EpubBlockKind.image,
        startChar: 0,
        imageHref: 'images/pic.png',
      ),
    ]);

    final paginator = EpubPaginator(
      content: content,
      chapterIndex: 0,
      typography: const EpubTypography(),
      contentWidth: 300,
      contentHeight: 400,
      loadImage: (href) async => const EpubImageInfo(1000, 500),
    );
    final layout = await paginator.paginate();

    final item = layout.pages.single.items.single as EpubImageItem;
    expect(item.width, 300);
    expect(item.height, 150, reason: '300 / (1000/500) = 150');
  });
}

EpubChapterContent _content(List<EpubBlock> blocks) {
  final charCount = blocks.fold<int>(0, (sum, block) => sum + block.charCount);
  return EpubChapterContent(
    href: 'text/ch1.xhtml',
    blocks: blocks,
    anchors: const <String, int>{},
    charCount: charCount,
  );
}
