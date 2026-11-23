import 'dart:io';

import 'package:flutter/services.dart';

/// Android 系统手势排除区。
///
/// 书签入口贴在屏幕右侧边，恰好落在系统的返回手势带里。把入口的竖向矩形报给
/// 系统后，落在这块区域内的手势会交给应用，不再触发返回。
///
/// - 仅 Android 生效，Windows 等平台 [isSupported] 为 false，调用直接跳过；
/// - 系统对每条边可排除的长度有上限（200 dp），[cropToBudget] 先按可用额度裁剪，
///   避免一次报满被系统裁掉后整体失效。
class SystemGestureExclusionService {
  const SystemGestureExclusionService();

  static const MethodChannel _channel = MethodChannel(
    'homepdfreader/gesture_exclusion',
  );

  /// 系统对每条边可排除长度的上限（dp）。
  static const double edgeBudget = 200;

  /// 当前平台是否支持手势排除区。
  bool get isSupported => Platform.isAndroid;

  /// 上报入口矩形（logical px，即 dp）。[screenSize] 用于裁掉屏幕外部分。
  Future<void> setRects(
    List<Rect> rects, {
    required Size screenSize,
  }) async {
    if (!isSupported) return;
    final cropped = cropToBudget(rects, screenSize: screenSize);
    if (cropped.isEmpty) {
      await clear();
      return;
    }
    try {
      await _channel.invokeMethod<void>('setExclusionRects', <String, Object>{
        'rects': cropped
            .map(
              (rect) => <String, double>{
                'left': rect.left,
                'top': rect.top,
                'right': rect.right,
                'bottom': rect.bottom,
              },
            )
            .toList(),
      });
    } on MissingPluginException {
      // 宿主未注册通道（旧版本/非 Android）：静默跳过。
    } on PlatformException {
      // 上报失败不影响阅读，下一帧还会再报。
    }
  }

  /// 清空排除区，避免离开阅读页后留下旧矩形。
  Future<void> clear() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('clearExclusionRects');
    } on MissingPluginException {
      // 同上。
    } on PlatformException {
      // 同上。
    }
  }

  /// 先裁到屏幕内，再按每条边的 200 dp 预算逐条裁剪。
  ///
  /// 贴近上/下边的矩形按宽度占用预算，贴近左/右边的矩形按高度占用预算；
  /// 预算用尽后的部分直接裁掉。纯函数，便于单测。
  static List<Rect> cropToBudget(
    List<Rect> rects, {
    required Size screenSize,
    double budget = edgeBudget,
  }) {
    final screen = Offset.zero & screenSize;
    final work = <Rect>[];
    for (final rect in rects) {
      final clipped = rect.intersect(screen);
      if (clipped.width <= 0 || clipped.height <= 0) continue;
      work.add(clipped);
    }

    var topBudget = budget;
    var bottomBudget = budget;
    var leftBudget = budget;
    var rightBudget = budget;
    // 屏幕边缘判定容差：亚像素误差不算贴边。
    const tolerance = 0.5;

    final result = <Rect>[];
    for (var rect in work) {
      var keep = true;
      if (rect.top <= tolerance) {
        final allowed = rect.width.clamp(0.0, topBudget).toDouble();
        if (allowed < rect.width) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.left + allowed, rect.bottom);
        }
        topBudget -= allowed;
        keep = keep && allowed > 0;
      }
      if (keep && rect.bottom >= screenSize.height - tolerance) {
        final allowed = rect.width.clamp(0.0, bottomBudget).toDouble();
        if (allowed < rect.width) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.left + allowed, rect.bottom);
        }
        bottomBudget -= allowed;
        keep = keep && allowed > 0;
      }
      if (keep && rect.left <= tolerance) {
        final allowed = rect.height.clamp(0.0, leftBudget).toDouble();
        if (allowed < rect.height) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + allowed);
        }
        leftBudget -= allowed;
        keep = keep && allowed > 0;
      }
      if (keep && rect.right >= screenSize.width - tolerance) {
        final allowed = rect.height.clamp(0.0, rightBudget).toDouble();
        if (allowed < rect.height) {
          rect = Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + allowed);
        }
        rightBudget -= allowed;
        keep = keep && allowed > 0;
      }
      if (keep && rect.width > 0 && rect.height > 0) result.add(rect);
    }
    return result;
  }
}
