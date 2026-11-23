import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/geometry/page_rect.dart';
import 'package:home_pdf_reader/core/geometry/selection_splitter.dart';

void main() {
  group('SelectionSplitter.splitByPage', () {
    test('按页分组并保持页序与页内顺序', () {
      final hits = <PageHit>[
        PageHit(pageIndex: 2, rect: PageRect.fromLTRB(0.1, 0.1, 0.5, 0.12)),
        PageHit(pageIndex: 1, rect: PageRect.fromLTRB(0.1, 0.5, 0.6, 0.52)),
        PageHit(pageIndex: 2, rect: PageRect.fromLTRB(0.1, 0.13, 0.4, 0.15)),
      ];
      final result = SelectionSplitter.splitByPage(hits);
      expect(result.length, 2);
      expect(result[0].pageIndex, 1);
      expect(result[0].rects.length, 1);
      expect(result[1].pageIndex, 2);
      expect(result[1].rects.length, 2);
      expect(result[1].rects[0].top, 0.1);
      expect(result[1].rects[1].top, 0.13);
    });

    test('丢弃负数页号与空矩形', () {
      final hits = <PageHit>[
        PageHit(pageIndex: -1, rect: PageRect.fromLTRB(0.1, 0.1, 0.2, 0.2)),
        PageHit(pageIndex: 0, rect: PageRect.fromLTRB(0.3, 0.3, 0.3, 0.3)),
        PageHit(pageIndex: 0, rect: PageRect.fromLTRB(0.4, 0.4, 0.5, 0.5)),
      ];
      final result = SelectionSplitter.splitByPage(hits);
      expect(result.length, 1);
      expect(result.single.rects.length, 1);
    });

    test('入库矩形已 roundTo6 且被裁剪', () {
      final hits = <PageHit>[
        PageHit(pageIndex: 0, rect: PageRect.fromLTRB(-1, 0.12345678, 2, 0.5)),
      ];
      final rect = SelectionSplitter.splitByPage(hits).single.rects.single;
      expect(rect.left, 0);
      expect(rect.right, 1);
      expect(rect.top, 0.123457);
    });
  });

  group('SelectionSplitter.mergeLines', () {
    test('同一行相邻矩形合并', () {
      final merged = SelectionSplitter.mergeLines(<PageRect>[
        PageRect.fromLTRB(0.1, 0.2, 0.3, 0.22),
        PageRect.fromLTRB(0.3, 0.2, 0.6, 0.22),
      ]);
      expect(merged.length, 1);
      expect(merged.single.left, 0.1);
      expect(merged.single.right, 0.6);
    });

    test('不同行不合并', () {
      final merged = SelectionSplitter.mergeLines(<PageRect>[
        PageRect.fromLTRB(0.1, 0.2, 0.3, 0.22),
        PageRect.fromLTRB(0.1, 0.25, 0.3, 0.27),
      ]);
      expect(merged.length, 2);
    });
  });
}
