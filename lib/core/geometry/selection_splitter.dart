import 'dart:math' as math;

import 'page_rect.dart';

/// 一次命中（字符/行）落在某一页上的矩形。
class PageHit {
  const PageHit({required this.pageIndex, required this.rect});

  /// 0 基页码。
  final int pageIndex;
  final PageRect rect;
}

/// 按页拆分后的选择结果，`rects` 按阅读顺序（先行后列）排列。
class PageSelection {
  const PageSelection({required this.pageIndex, required this.rects});

  final int pageIndex;
  final List<PageRect> rects;

  @override
  String toString() => 'PageSelection(page: $pageIndex, rects: ${rects.length})';
}

/// 跨页选择拆分器。
abstract final class SelectionSplitter {
  /// 把多行命中按页分组，保持页出现顺序与页内矩形顺序。
  ///
  /// 空矩形与越界页号（负数）会被丢弃。
  static List<PageSelection> splitByPage(Iterable<PageHit> hits) {
    final grouped = <int, List<PageRect>>{};
    for (final hit in hits) {
      if (hit.pageIndex < 0) continue;
      final rect = hit.rect.clampToUnit().roundTo6();
      if (rect.isEmpty) continue;
      grouped.putIfAbsent(hit.pageIndex, () => <PageRect>[]).add(rect);
    }
    final pages = grouped.keys.toList()..sort();
    return [
      for (final page in pages) PageSelection(pageIndex: page, rects: List.unmodifiable(grouped[page]!)),
    ];
  }

  /// 把相邻/重叠的行矩形合并为连续行块（仅用于展示，不改变入库粒度）。
  static List<PageRect> mergeLines(List<PageRect> lineRects) {
    if (lineRects.isEmpty) return const <PageRect>[];
    final sorted = [...lineRects]..sort((a, b) => a.top.compareTo(b.top));
    final merged = <PageRect>[];
    for (final rect in sorted) {
      if (rect.isEmpty) continue;
      if (merged.isEmpty) {
        merged.add(rect);
        continue;
      }
      final last = merged.last;
      final verticalOverlap = math.min(last.bottom, rect.bottom) - math.max(last.top, rect.top);
      final minHeight = math.min(last.height, rect.height);
      final sameLine = minHeight > 0 && verticalOverlap > minHeight * 0.5;
      final horizontalTouch = rect.left <= last.right + 0.002;
      if (sameLine && horizontalTouch) {
        merged[merged.length - 1] = last.union(rect);
      } else {
        merged.add(rect);
      }
    }
    return List.unmodifiable(merged);
  }
}
