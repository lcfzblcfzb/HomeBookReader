import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/features/reader/presentation/bookmark_entry_layout.dart';

void main() {
  group('BookmarkEntryLayout', () {
    // 测试画布 800×600：入口贴右侧边，纵向可用 0..468（600 − 入口长度 132）。
    const portrait = BookmarkEntryLayout(
      isLandscape: false,
      right: 800,
      minTop: 0,
      maxTop: 468,
    );

    test('没有历史位置时贴右上角', () {
      expect(portrait.initialTop(null), 0);
    });

    test('按比例还原纵向坐标并夹在可用范围内', () {
      expect(portrait.initialTop(0), 0);
      expect(portrait.initialTop(0.5), 234);
      expect(portrait.initialTop(1), 468);
      expect(portrait.initialTop(-0.3), 0);
      expect(portrait.initialTop(1.3), 468);
    });

    test('纵向坐标与比例可互转', () {
      expect(portrait.ratioOf(234), 0.5);
      expect(portrait.ratioOf(-100), 0);
      expect(portrait.ratioOf(9999), 1);
      expect(portrait.initialTop(portrait.ratioOf(120)), closeTo(120, 1e-9));
    });

    test('可用跨度为零时退化到上边界', () {
      const narrow = BookmarkEntryLayout(
        isLandscape: true,
        right: 640,
        minTop: 24,
        maxTop: 24,
      );
      expect(narrow.span, 0);
      expect(narrow.initialTop(0.8), 24);
      expect(narrow.ratioOf(24), 0);
    });

    test('安全区参与 clamp，拖动不会越界', () {
      const withInset = BookmarkEntryLayout(
        isLandscape: true,
        right: 744,
        minTop: 12,
        maxTop: 380,
      );
      expect(withInset.clampTop(-30), 12);
      expect(withInset.clampTop(200), 200);
      expect(withInset.clampTop(999), 380);
    });

    test('朝向不同视为不同布局（旋转要重新贴边）', () {
      const landscape = BookmarkEntryLayout(
        isLandscape: true,
        right: 800,
        minTop: 0,
        maxTop: 468,
      );
      expect(landscape == portrait, isFalse);
      expect(
        landscape ==
            const BookmarkEntryLayout(
              isLandscape: true,
              right: 800,
              minTop: 0,
              maxTop: 468,
            ),
        isTrue,
      );
    });
  });
}
