import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/platform/system_gesture_exclusion.dart';

void main() {
  const screen = Size(400, 800);

  group('SystemGestureExclusionService.cropToBudget', () {
    test('贴顶入口在 200dp 预算内保持原样', () {
      const entry = Rect.fromLTWH(268, 0, 132, 40);
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[entry],
        screenSize: screen,
      );
      expect(result, <Rect>[entry]);
    });

    test('贴顶矩形宽度超过 200dp 时按预算裁到 200', () {
      const wide = Rect.fromLTWH(0, 0, 260, 40);
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[wide],
        screenSize: screen,
      );
      expect(result, <Rect>[const Rect.fromLTWH(0, 0, 200, 40)]);
    });

    test('同一条边的预算被多条矩形依次扣减', () {
      const first = Rect.fromLTWH(0, 0, 132, 40);
      const second = Rect.fromLTWH(132, 0, 132, 40);
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[first, second],
        screenSize: screen,
      );
      expect(result, <Rect>[
        first,
        // 剩余额度 200 - 132 = 68。
        const Rect.fromLTRB(132, 0, 200, 40),
      ]);
    });

    test('预算用尽后的矩形被丢弃', () {
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[
          const Rect.fromLTWH(0, 0, 200, 40),
          const Rect.fromLTWH(200, 0, 60, 40),
        ],
        screenSize: screen,
      );
      expect(result, <Rect>[const Rect.fromLTWH(0, 0, 200, 40)]);
    });

    test('不贴边的矩形只按屏幕裁剪，不占边缘预算', () {
      const middle = Rect.fromLTWH(10, 100, 132, 40);
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[middle],
        screenSize: screen,
      );
      expect(result, <Rect>[middle]);
    });

    test('左右边按高度占用 200dp 预算', () {
      const rightEdge = Rect.fromLTWH(300, 100, 100, 400);
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[rightEdge],
        screenSize: screen,
      );
      expect(result, <Rect>[const Rect.fromLTRB(300, 100, 400, 300)]);
    });

    test('屏幕外的部分先被裁掉', () {
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[const Rect.fromLTWH(-50, -50, 100, 100)],
        screenSize: screen,
      );
      expect(result, <Rect>[const Rect.fromLTWH(0, 0, 50, 50)]);
    });

    test('完全在屏幕外时返回空列表', () {
      final result = SystemGestureExclusionService.cropToBudget(
        <Rect>[const Rect.fromLTWH(500, 900, 600, 1000)],
        screenSize: screen,
      );
      expect(result, isEmpty);
    });
  });
}
