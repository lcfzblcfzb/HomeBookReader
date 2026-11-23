import 'dart:math' as math;

/// 页内归一化矩形：坐标取值 `[0,1]`，与设备、屏幕尺寸、缩放级别无关。
///
/// 存储约定：一次划线可能跨多行，存为多个 [PageRect]，按「先行后列」排序；
/// 跨页选择按页拆成多条记录。
class PageRect {
  const PageRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 构造并规范化：非法值（NaN）归零、无穷按边界取 0/1；
  /// 保证 `left <= right`、`top <= bottom`。
  factory PageRect.fromLTRB(double left, double top, double right, double bottom) {
    final l = _normalize(left);
    final r = _normalize(right);
    final t = _normalize(top);
    final b = _normalize(bottom);
    return PageRect(
      left: math.min(l, r),
      top: math.min(t, b),
      right: math.max(l, r),
      bottom: math.max(t, b),
    );
  }

  /// 像素矩形 → 归一化矩形。
  factory PageRect.fromPixels({
    required double left,
    required double top,
    required double right,
    required double bottom,
    required double pageWidth,
    required double pageHeight,
  }) {
    assert(pageWidth > 0 && pageHeight > 0, '页面尺寸必须为正数');
    return PageRect.fromLTRB(left / pageWidth, top / pageHeight, right / pageWidth, bottom / pageHeight);
  }

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  bool get isEmpty => width <= 0 || height <= 0;

  /// 归一化矩形 → 像素矩形（四元组，避免在纯 Dart 层引入 Flutter 类型）。
  ({double left, double top, double right, double bottom}) toPixels(double pageWidth, double pageHeight) => (
        left: left * pageWidth,
        top: top * pageHeight,
        right: right * pageWidth,
        bottom: bottom * pageHeight,
      );

  /// 裁剪到 `[0,1]`，非法值归零。
  PageRect clampToUnit() => PageRect.fromLTRB(left, top, right, bottom);

  /// 四舍五入到 6 位小数（入库前调用）。
  PageRect roundTo6() => PageRect(
        left: _round6(left),
        top: _round6(top),
        right: _round6(right),
        bottom: _round6(bottom),
      );

  PageRect inflate(double dx, double dy) => PageRect(
        left: _normalize(left - dx),
        top: _normalize(top - dy),
        right: _normalize(right + dx),
        bottom: _normalize(bottom + dy),
      );

  bool contains(double x, double y) => x >= left && x <= right && y >= top && y <= bottom;

  bool overlaps(PageRect other) =>
      left < other.right && right > other.left && top < other.bottom && bottom > other.top;

  PageRect union(PageRect other) => PageRect.fromLTRB(
        math.min(left, other.left),
        math.min(top, other.top),
        math.max(right, other.right),
        math.max(bottom, other.bottom),
      );

  /// 入库格式：`[x0, y0, x1, y1]`，按 `roundTo6` 收敛。
  List<double> toJsonList() {
    final r = roundTo6();
    return <double>[r.left, r.top, r.right, r.bottom];
  }

  static PageRect fromJsonList(List<dynamic> json) {
    if (json.length != 4) {
      throw FormatException('PageRect 需要 4 个数值，实际 ${json.length} 个');
    }
    final values = json.map((e) {
      if (e is! num) throw const FormatException('PageRect 仅接受数值');
      return e.toDouble();
    }).toList(growable: false);
    return PageRect.fromLTRB(values[0], values[1], values[2], values[3]);
  }

  @override
  bool operator ==(Object other) =>
      other is PageRect &&
      other.left == left &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'PageRect($left, $top, $right, $bottom)';
}

double _normalize(double v) {
  if (v.isNaN) return 0;
  if (v <= 0) return 0;
  if (v >= 1) return 1;
  return v;
}

double _round6(double v) => (v * 1000000).roundToDouble() / 1000000;
