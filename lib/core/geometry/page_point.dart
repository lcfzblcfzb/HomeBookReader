/// 页内归一化坐标点。
///
/// 基准：以「用户实际看到的页面显示框」（旋转后的 crop box）为基准，
/// 左上角为原点，x 向右、y 向下，取值归一化到 `[0, 1]`。
class PagePoint {
  const PagePoint(this.x, this.y);

  /// 构造并裁剪到 `[0,1]`，非有限值按 0 处理。
  factory PagePoint.clamped(double x, double y) => PagePoint(
        _normalize(x),
        _normalize(y),
      );

  final double x;
  final double y;

  static const PagePoint zero = PagePoint(0, 0);

  bool get isFinite => x.isFinite && y.isFinite;

  /// 像素坐标 → 归一化坐标。
  factory PagePoint.fromPixels(double px, double py, double pageWidth, double pageHeight) {
    assert(pageWidth > 0 && pageHeight > 0, '页面尺寸必须为正数');
    return PagePoint.clamped(px / pageWidth, py / pageHeight);
  }

  /// 归一化坐标 → 像素坐标。
  ({double x, double y}) toPixels(double pageWidth, double pageHeight) =>
      (x: x * pageWidth, y: y * pageHeight);

  /// 四舍五入保留 6 位小数并裁剪。
  PagePoint roundTo6() => PagePoint(_round6(_normalize(x)), _round6(_normalize(y)));

  Map<String, double> toJson() => {'x': roundTo6().x, 'y': roundTo6().y};

  static PagePoint fromJson(Map<String, dynamic> json) {
    final x = json['x'];
    final y = json['y'];
    if (x is! num || y is! num) {
      throw const FormatException('PagePoint JSON 缺少数值字段 x/y');
    }
    return PagePoint.clamped(x.toDouble(), y.toDouble());
  }

  @override
  bool operator ==(Object other) => other is PagePoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'PagePoint($x, $y)';
}

double _normalize(double v) {
  if (!v.isFinite) return 0;
  if (v < 0) return 0;
  if (v > 1) return 1;
  return v;
}

double _round6(double v) => (v * 1000000).roundToDouble() / 1000000;
