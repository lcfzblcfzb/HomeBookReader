import 'package:flutter/foundation.dart';

/// 书签入口在阅读页 Stack 坐标系中的活动范围。
///
/// 入口是竖向条，贴在**当前朝向的右侧边缘**：
/// - 竖屏：右边缘是长边；
/// - 横屏：右边缘是短边。
///
/// 两种情况都贴屏幕物理右侧，纵向可用范围随朝向变化。
/// 纵向位置以 0..1 的比例持久化，窗口尺寸变化后仍能还原相对位置；
/// 竖屏与横屏各自一份，用 [isLandscape] 区分。
@immutable
class BookmarkEntryLayout {
  const BookmarkEntryLayout({
    required this.isLandscape,
    required this.right,
    required this.minTop,
    required this.maxTop,
  });

  /// 当前是否横屏（右边缘为短边）。
  final bool isLandscape;

  /// 入口盒右边缘的横坐标；安全区参与后通常等于屏宽 − 右内边距。
  final double right;

  /// 入口盒上边缘可取的纵坐标下界（安全区上内边界）。
  final double minTop;

  /// 入口盒上边缘可取的纵坐标上界（安全区下内边界减入口长度）。
  final double maxTop;

  /// 可滑动的纵向跨度。
  double get span => (maxTop - minTop).clamp(0, double.infinity);

  double clampTop(double top) => top.clamp(minTop, maxTop).toDouble();

  /// 无历史位置（比例为空）时贴右上角（纵向最上）。
  double initialTop(double? ratio) {
    if (ratio == null) return minTop;
    return clampTop(minTop + ratio * span);
  }

  /// 把纵向坐标换算成 0..1 的比例，用于按朝向持久化。
  double ratioOf(double top) =>
      span <= 0 ? 0 : (clampTop(top) - minTop) / span;

  @override
  bool operator ==(Object other) =>
      other is BookmarkEntryLayout &&
      other.isLandscape == isLandscape &&
      other.right == right &&
      other.minTop == minTop &&
      other.maxTop == maxTop;

  @override
  int get hashCode => Object.hash(isLandscape, right, minTop, maxTop);

  @override
  String toString() =>
      'BookmarkEntryLayout(landscape: $isLandscape, right: $right, '
      'top: $minTop..$maxTop)';
}
