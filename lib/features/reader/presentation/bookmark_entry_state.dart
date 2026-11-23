import 'dart:ui';

import 'package:flutter/foundation.dart';

/// 书签入口的视觉状态。
enum BookmarkEntryState {
  /// 静止：默认态，折叠露出。
  idle,

  /// 拖拽：用户按住并拖动期间。
  dragging,

  /// 激活：面板打开期间。
  active,
}

/// 由「是否拖动 + 面板是否打开」推导状态。
///
/// 迁移规则集中在这里，避免散落在手势与页面代码里：
/// - 按住并移动 → [BookmarkEntryState.dragging]；
/// - 拖起后松手 → 回 [BookmarkEntryState.idle]（吸附动画由位置逻辑保留）；
/// - 原地按住不移动就松手 → 按单击处理，不会卡在 dragging；
/// - 单击打开面板 → [BookmarkEntryState.active]；面板关闭 → idle。
BookmarkEntryState resolveBookmarkEntryState({
  required bool isDragging,
  required bool panelOpen,
}) {
  if (isDragging) return BookmarkEntryState.dragging;
  if (panelOpen) return BookmarkEntryState.active;
  return BookmarkEntryState.idle;
}

/// 单态视觉参数：只允许阴影与极小位移差，不做缩放、旋转或拉伸。
///
/// 参数集中放在 [ReaderUiConfig.entryStateVisuals]，后期给某一态单独加动画时
/// 只需要改配置表，不必翻各 widget。
@immutable
class BookmarkEntryStateStyle {
  const BookmarkEntryStateStyle({
    this.shadowBlur = 0,
    this.shadowOpacity = 0,
    this.shadowOffset = Offset.zero,
    this.pullOffset = 0,
  });

  /// 阴影模糊半径。
  final double shadowBlur;

  /// 阴影不透明度（0..1）。
  final double shadowOpacity;

  /// 阴影偏移；入口贴右侧边，因此指向屏幕内（负 x）。
  final Offset shadowOffset;

  /// 额外向外（贴边方向）平移的像素，用于表达「被拉扯」；不做形变。
  final double pullOffset;

  bool get hasShadow => shadowOpacity > 0 && shadowBlur > 0;

  static BookmarkEntryStateStyle lerp(
    BookmarkEntryStateStyle from,
    BookmarkEntryStateStyle to,
    double t,
  ) {
    return BookmarkEntryStateStyle(
      shadowBlur: lerpDouble(from.shadowBlur, to.shadowBlur, t)!,
      shadowOpacity: lerpDouble(from.shadowOpacity, to.shadowOpacity, t)!,
      shadowOffset: Offset.lerp(from.shadowOffset, to.shadowOffset, t)!,
      pullOffset: lerpDouble(from.pullOffset, to.pullOffset, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BookmarkEntryStateStyle &&
      other.shadowBlur == shadowBlur &&
      other.shadowOpacity == shadowOpacity &&
      other.shadowOffset == shadowOffset &&
      other.pullOffset == pullOffset;

  @override
  int get hashCode => Object.hash(
    shadowBlur,
    shadowOpacity,
    shadowOffset,
    pullOffset,
  );
}
