import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/features/reader/presentation/bookmark_entry_layout.dart';
import 'package:home_pdf_reader/features/reader/presentation/reader_ui_config.dart';
import 'package:home_pdf_reader/features/reader/widgets/bookmark_entry.dart';
import 'package:home_pdf_reader/features/reader/widgets/bookmark_entry_artwork.dart';

void main() {
  // 测试画布默认 800×600：入口竖向条（厚 40、长 132）贴右侧边。
  const portrait = BookmarkEntryLayout(
    isLandscape: false,
    right: 800,
    minTop: 0,
    maxTop: 468,
  );

  Future<void> pumpEntry(
    WidgetTester tester, {
    required BookmarkEntryLayout layout,
    double? initialRatio,
    bool panelOpen = false,
    VoidCallback? onActivate,
    ValueChanged<double>? onSettled,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: BookmarkEntry(
                  panelOpen: panelOpen,
                  layout: layout,
                  initialRatio: initialRatio,
                  onActivate: onActivate ?? () {},
                  onSettled: onSettled ?? (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 入口绘制层的当前道具：头部露出进度与拖拽外移量。
  BookmarkEntryArtwork artwork(WidgetTester tester) =>
      tester.widget<BookmarkEntryArtwork>(find.byType(BookmarkEntryArtwork));

  /// 素材沿外法线的位移（贴边方向为负 y），0 表示完整可见。
  double artworkOffsetY(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey<String>('bookmark-entry-art-offset')),
    );
    return transform.transform.storage[13];
  }

  test('旋转与贴边绑定：贴右侧时素材顶端朝屏幕外', () {
    expect(ReaderUiConfig.entrySide, BookmarkEntrySide.right);
    expect(ReaderUiConfig.entryQuarterTurns, 1);
    expect(ReaderUiConfig.entryStaticOutwardRatio, greaterThan(0));
    expect(ReaderUiConfig.entryStaticOutwardRatio, lessThan(1));
  });

  testWidgets('首次进入完整贴右侧边，只露爪不露头', (tester) async {
    await pumpEntry(tester, layout: portrait);
    final rect = tester.getRect(find.byType(BookmarkEntryArtwork));
    expect(rect.left, 800 - ReaderUiConfig.entryThickness);
    expect(rect.width, ReaderUiConfig.entryThickness);
    expect(rect.top, 0);
    expect(rect.height, ReaderUiConfig.entryLength);
    // 静止态整张素材被沿外法线推出入口，屏内只剩底部一截（爪部）。
    expect(artwork(tester).headReveal, 0);
    expect(
      artworkOffsetY(tester),
      closeTo(
        -ReaderUiConfig.entryThickness *
            ReaderUiConfig.entryStaticOutwardRatio,
        0.5,
      ),
    );
  });

  testWidgets('点击入口打开面板', (tester) async {
    var activated = false;
    await pumpEntry(
      tester,
      layout: portrait,
      onActivate: () => activated = true,
    );
    await tester.tapAt(const Offset(790, 66));
    await tester.pump();
    expect(activated, isTrue);
  });

  testWidgets('纵向拖动跟手，松手吸附右侧边且不误触打开面板', (tester) async {
    var activated = false;
    double? settledRatio;
    await pumpEntry(
      tester,
      layout: portrait,
      onActivate: () => activated = true,
      onSettled: (ratio) => settledRatio = ratio,
    );

    final gesture = await tester.startGesture(const Offset(790, 66));
    // 先起帧再推进时长，等滑出动画结束，折叠位移归零，便于断言精确坐标。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveTo(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 16));

    // 拖动中跟手：入口左边缘 = 760 + (400-790) = 370，纵向跟到 300 附近。
    final dragging = tester.getRect(find.byType(BookmarkEntryArtwork));
    expect(dragging.left, closeTo(370, 0.5));
    expect(dragging.top, closeTo(234, 0.5));
    // 拖拽态仍是「只露爪」，靠极小的外移表达拉扯，不做形变。
    expect(artwork(tester).headReveal, 0);

    // 首个 tick 只建立起始时间，再推进时长让三态过渡走到 dragging。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(artwork(tester).pullOffset, greaterThan(0));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(activated, isFalse);
    // 纵向落点 234 / 468 = 0.5。
    expect(settledRatio, closeTo(0.5, 0.001));
    final settled = tester.getRect(find.byType(BookmarkEntryArtwork));
    expect(settled.left, closeTo(760, 0.5));
    expect(settled.top, closeTo(234, 0.5));
  });

  testWidgets('拖动时只多移一点、不缩放，松手回 idle 位移', (tester) async {
    await pumpEntry(tester, layout: portrait);
    expect(
      artworkOffsetY(tester),
      closeTo(-ReaderUiConfig.entryThickness *
          ReaderUiConfig.entryStaticOutwardRatio, 0.5),
    );

    final gesture = await tester.startGesture(const Offset(790, 66));
    await gesture.moveTo(const Offset(700, 250));
    // 动画控制器在下一帧才拿到首个 tick，先起帧再推进时长。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(artwork(tester).pullOffset, closeTo(2, 1e-3));
    expect(
      artworkOffsetY(tester),
      closeTo(-ReaderUiConfig.entryThickness *
          ReaderUiConfig.entryStaticOutwardRatio - 2, 0.5),
    );

    // 松手后立即回 idle，位置吸附动画另行播放。
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(artwork(tester).pullOffset, closeTo(0, 1e-3));
    await tester.pumpAndSettle();
  });

  testWidgets('面板打开进入 active 露出头部，关闭回 idle 收头', (tester) async {
    await pumpEntry(tester, layout: portrait);
    expect(artwork(tester).headReveal, 0);
    expect(artwork(tester).pullOffset, 0);

    await pumpEntry(tester, layout: portrait, panelOpen: true);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    // 头部完全露出：位移归零，整张素材回到入口内。
    expect(artwork(tester).headReveal, closeTo(1, 1e-3));
    expect(artworkOffsetY(tester), closeTo(0, 0.5));

    await pumpEntry(tester, layout: portrait);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(artwork(tester).headReveal, closeTo(0, 1e-3));
    expect(artworkOffsetY(tester), closeTo(-28.8, 0.5));
  });

  testWidgets('旋转后按横屏记住的位置重新贴右侧边', (tester) async {
    await pumpEntry(tester, layout: portrait, initialRatio: 0.5);
    expect(tester.getRect(find.byType(BookmarkEntryArtwork)).top, 234);

    // 横屏短边更矮：可用纵向范围变小，比例不变时落点随范围缩放。
    const landscape = BookmarkEntryLayout(
      isLandscape: true,
      right: 800,
      minTop: 0,
      maxTop: 300,
    );
    await pumpEntry(tester, layout: landscape, initialRatio: 0.2);
    await tester.pumpAndSettle();

    final rect = tester.getRect(find.byType(BookmarkEntryArtwork));
    expect(rect.top, closeTo(60, 0.5));
    expect(rect.left, closeTo(760, 0.5));
  });
}
