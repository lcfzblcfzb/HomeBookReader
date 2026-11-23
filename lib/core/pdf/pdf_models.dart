import '../geometry/page_rect.dart';

/// 页面尺寸，单位 pt（PDF 用户空间，1pt = 1/72 inch），已按页面旋转换算。
class PageSize {
  const PageSize(this.width, this.height);

  final double width;
  final double height;

  double get aspectRatio => width / height;

  @override
  String toString() => 'PageSize($width x $height)';
}

/// 逐行文本：一行内的字符范围 + 该行矩形 + 每个字符的矩形。
class PdfTextLine {
  const PdfTextLine({
    required this.text,
    required this.start,
    required this.end,
    required this.bounds,
    required this.charRects,
  });

  final String text;

  /// 在全页文本中的起始下标（含）。
  final int start;

  /// 在全页文本中的结束下标（不含）。
  final int end;

  /// 该行在页面显示框中的归一化矩形。
  final PageRect bounds;

  /// 逐字符归一化矩形，可能短于 [text]（缺字形时）。
  final List<PageRect> charRects;

  bool get isEmpty => text.trim().isEmpty;
}

/// 目录节点（对应 PDF outline）。
class PdfOutlineNode {
  const PdfOutlineNode({
    required this.title,
    required this.level,
    required this.pageIndex,
    this.children = const <PdfOutlineNode>[],
  });

  final String title;

  /// 层级，从 1 开始。
  final int level;

  /// 目标页，0 基；无法解析时为 -1。
  final int pageIndex;

  final List<PdfOutlineNode> children;
}

enum PdfFailureKind {
  /// 文件损坏或不是 PDF。
  corrupted,

  /// 需要口令。
  encrypted,

  /// 格式可解析但能力不支持。
  unsupported,

  unknown,
}

class PdfOpenException implements Exception {
  const PdfOpenException(this.kind, this.message);

  final PdfFailureKind kind;
  final String message;

  @override
  String toString() => 'PdfOpenException($kind): $message';
}
