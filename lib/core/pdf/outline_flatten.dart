import 'pdf_models.dart';

/// 扁平化后的目录项：面板按列表渲染，父子关系用 [parentIndex] 表示。
class TocFlatNode {
  const TocFlatNode({
    required this.title,
    required this.level,
    required this.pageIndex,
    required this.parentIndex,
    required this.sortOrder,
  });

  final String title;

  /// 层级，从 1 开始。
  final int level;

  /// 目标页，0 基；-1 表示无法解析。
  final int pageIndex;

  /// 父项在扁平列表中的下标，根为 null。
  final int? parentIndex;

  /// 文档顺序。
  final int sortOrder;
}

/// 深度优先展开 outline，保持文档顺序。
List<TocFlatNode> flattenOutline(List<PdfOutlineNode> nodes) {
  final result = <TocFlatNode>[];
  void walk(List<PdfOutlineNode> nodes, int? parentIndex) {
    for (final node in nodes) {
      final index = result.length;
      result.add(
        TocFlatNode(
          title: node.title.trim().isEmpty ? '未命名章节' : node.title.trim(),
          level: node.level,
          pageIndex: node.pageIndex,
          parentIndex: parentIndex,
          sortOrder: index,
        ),
      );
      walk(node.children, index);
    }
  }

  walk(nodes, null);
  return result;
}

/// 当前页所属章节：文档顺序中最后一个目标页不超过 [pageIndex] 的条目。
int? currentSectionIndex(List<TocFlatNode> nodes, int pageIndex) {
  int? current;
  for (var i = 0; i < nodes.length; i++) {
    final target = nodes[i].pageIndex;
    if (target < 0 || target > pageIndex) continue;
    current = i;
  }
  return current;
}
