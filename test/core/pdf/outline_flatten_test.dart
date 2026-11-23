import 'package:flutter_test/flutter_test.dart';

import 'package:home_pdf_reader/core/pdf/outline_flatten.dart';
import 'package:home_pdf_reader/core/pdf/pdf_models.dart';

PdfOutlineNode node(
  String title,
  int pageIndex, {
  int level = 1,
  List<PdfOutlineNode> children = const <PdfOutlineNode>[],
}) =>
    PdfOutlineNode(
      title: title,
      level: level,
      pageIndex: pageIndex,
      children: children,
    );

void main() {
  group('flattenOutline', () {
    test('深度优先展开，保留层级与父子下标', () {
      final flat = flattenOutline(<PdfOutlineNode>[
        node(
          '第一章',
          0,
          children: <PdfOutlineNode>[
            node('1.1', 2, level: 2),
            node('1.2', 4, level: 2),
          ],
        ),
        node('第二章', 6),
      ]);

      expect(flat.map((e) => e.title), <String>['第一章', '1.1', '1.2', '第二章']);
      expect(flat.map((e) => e.sortOrder), <int>[0, 1, 2, 3]);
      expect(flat.map((e) => e.level), <int>[1, 2, 2, 1]);
      expect(flat.map((e) => e.parentIndex), <int?>[null, 0, 0, null]);
    });

    test('空目录返回空列表', () {
      expect(flattenOutline(const <PdfOutlineNode>[]), isEmpty);
    });

    test('空白标题回退为未命名章节', () {
      expect(flattenOutline(<PdfOutlineNode>[node('  ', 1)]).single.title, '未命名章节');
    });
  });

  group('currentSectionIndex', () {
    final flat = flattenOutline(<PdfOutlineNode>[
      node('第一章', 0, children: <PdfOutlineNode>[node('1.1', 2, level: 2)]),
      node('第二章', 5),
      node('损坏项', -1),
    ]);

    test('落在章内取最近一个起始页不超过当前页的条目', () {
      expect(currentSectionIndex(flat, 0), 0);
      expect(currentSectionIndex(flat, 3), 1);
      expect(currentSectionIndex(flat, 5), 2);
    });

    test('损坏条目（-1）不参与命中', () {
      expect(currentSectionIndex(flat, 9), 2);
    });
  });
}
