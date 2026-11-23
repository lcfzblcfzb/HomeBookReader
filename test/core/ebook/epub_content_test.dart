import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/epub_content.dart';

void main() {
  test('解析标题、段落、粗斜体、列表、引用、图片与锚点', () {
    final content = EpubContentParser.parse(
      '''
<html><body>
  <h1 id="top">第一章</h1>
  <p>普通<strong>加粗</strong>与<em>斜体</em>文字。</p>
  <ul>
    <li>苹果</li>
    <li>香蕉
      <ol><li>熟透</li></ol>
    </li>
  </ul>
  <blockquote><p>引用的一句话。</p></blockquote>
  <p><img src="../images/pic.png" alt="插图"/></p>
  <hr/>
</body></html>
''',
      chapterHref: 'OEBPS/text/ch1.xhtml',
    );

    final kinds = content.blocks.map((block) => block.kind).toList();
    expect(kinds, containsAllInOrder(<EpubBlockKind>[
      EpubBlockKind.heading1,
      EpubBlockKind.paragraph,
      EpubBlockKind.listItem,
      EpubBlockKind.listItem,
      EpubBlockKind.listItem,
      EpubBlockKind.quote,
      EpubBlockKind.image,
      EpubBlockKind.divider,
    ]));

    final firstParagraph = content.blocks[1];
    expect(firstParagraph.plainText, '普通加粗与斜体文字。');
    expect(
      firstParagraph.runs.where((run) => run.bold).map((run) => run.text),
      contains('加粗'),
    );
    expect(
      firstParagraph.runs.where((run) => run.italic).map((run) => run.text),
      contains('斜体'),
    );

    final outerItems = content.blocks
        .where((block) => block.kind == EpubBlockKind.listItem)
        .toList();
    expect(outerItems[0].listLevel, 1);
    expect(outerItems[0].ordered, isFalse);
    expect(outerItems[2].listLevel, 2);
    expect(outerItems[2].ordered, isTrue);

    expect(content.blocks[5].kind, EpubBlockKind.quote);
    expect(content.blocks[6].imageHref, 'OEBPS/images/pic.png');

    expect(content.anchors['top'], 0);
    expect(content.charCount, greaterThan(20));
  });

  test('损坏的 XHTML 给出可展示的中文错误', () {
    expect(
      () => EpubContentParser.parse(
        '<html><body><p>没闭合',
        chapterHref: 'a.xhtml',
      ),
      throwsA(
        isA<EpubContentException>().having(
          (error) => error.reason,
          'reason',
          contains('解析失败'),
        ),
      ),
    );
  });
}
