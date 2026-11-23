import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/geometry/page_point.dart';
import 'package:home_pdf_reader/core/geometry/page_rect.dart';

void main() {
  group('PageRect 规范化', () {
    test('构造时自动交换左右/上下并裁剪', () {
      final rect = PageRect.fromLTRB(0.8, 0.9, 0.2, 0.1);
      expect(rect.left, 0.2);
      expect(rect.top, 0.1);
      expect(rect.right, 0.8);
      expect(rect.bottom, 0.9);
    });

    test('越界与非法值被裁剪到 [0,1]', () {
      final rect = PageRect.fromLTRB(-1, -2, 5, 9);
      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.right, 1);
      expect(rect.bottom, 1);

      final nan = PageRect.fromLTRB(double.nan, 0.2, 0.4, double.infinity);
      expect(nan.left, 0);
      expect(nan.bottom, 1);
    });

    test('roundTo6 保留 6 位小数', () {
      final rect = PageRect.fromLTRB(0.12345678, 0.2, 0.3, 0.4000001);
      expect(rect.roundTo6().left, 0.123457);
      expect(rect.roundTo6().bottom, 0.4);
    });
  });

  group('像素 ↔ 归一化往返', () {
    test('随机矩形在多种页面尺寸下往返一致', () {
      final random = Random(20261113);
      const sizes = <(double, double)>[(612, 792), (595.276, 841.89), (1920, 1080), (2160, 3840)];
      for (final (pageWidth, pageHeight) in sizes) {
        for (var i = 0; i < 200; i++) {
          final left = random.nextDouble();
          final top = random.nextDouble();
          final right = random.nextDouble();
          final bottom = random.nextDouble();
          final original = PageRect.fromLTRB(left, top, right, bottom);
          final pixels = original.toPixels(pageWidth, pageHeight);
          final roundTrip = PageRect.fromPixels(
            left: pixels.left,
            top: pixels.top,
            right: pixels.right,
            bottom: pixels.bottom,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
          );
          expect(roundTrip.left, closeTo(original.left, 1e-9));
          expect(roundTrip.top, closeTo(original.top, 1e-9));
          expect(roundTrip.right, closeTo(original.right, 1e-9));
          expect(roundTrip.bottom, closeTo(original.bottom, 1e-9));
        }
      }
    });

    test('缩放投影一致性：同一归一化矩形在不同缩放下还原到同一用户空间位置', () {
      final rect = PageRect.fromLTRB(0.1, 0.2, 0.35, 0.28);
      for (final scale in <double>[1, 2, 4]) {
        final pixels = rect.toPixels(600 * scale, 800 * scale);
        final userSpace = PageRect.fromPixels(
          left: pixels.left,
          top: pixels.top,
          right: pixels.right,
          bottom: pixels.bottom,
          pageWidth: 600 * scale,
          pageHeight: 800 * scale,
        );
        expect(userSpace.left, closeTo(rect.left, 1e-9));
        expect(userSpace.right, closeTo(rect.right, 1e-9));
      }
    });
  });

  group('PageRect JSON', () {
    test('序列化与反序列化对称', () {
      final rect = PageRect.fromLTRB(0.123456789, 0.25, 0.75, 0.987654321);
      final restored = PageRect.fromJsonList(rect.toJsonList());
      expect(restored, rect.roundTo6());
    });

    test('非法长度与类型抛 FormatException', () {
      expect(() => PageRect.fromJsonList(<dynamic>[0.1, 0.2, 0.3]), throwsFormatException);
      expect(() => PageRect.fromJsonList(<dynamic>[0.1, 0.2, 'x', 0.4]), throwsFormatException);
    });
  });

  group('PagePoint', () {
    test('clamped 处理越界与非法值', () {
      expect(PagePoint.clamped(-1, 2), const PagePoint(0, 1));
      expect(PagePoint.clamped(double.nan, double.infinity), PagePoint.zero);
    });

    test('像素换算往返', () {
      final point = PagePoint.fromPixels(306, 396, 612, 792);
      expect(point.x, closeTo(0.5, 1e-12));
      final pixels = point.toPixels(612, 792);
      expect(pixels.x, closeTo(306, 1e-9));
      expect(pixels.y, closeTo(396, 1e-9));
    });
  });
}
