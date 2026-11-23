import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/features/reader/presentation/bookmark_entry_state.dart';
import 'package:home_pdf_reader/features/reader/presentation/reader_ui_config.dart';

void main() {
  group('状态迁移', () {
    test('默认是 idle', () {
      expect(
        resolveBookmarkEntryState(isDragging: false, panelOpen: false),
        BookmarkEntryState.idle,
      );
    });

    test('原地按住不移动按单击处理，不进入 dragging', () {
      // 按下但未超过 touch slop 时 isDragging 仍为 false。
      expect(
        resolveBookmarkEntryState(isDragging: false, panelOpen: false),
        BookmarkEntryState.idle,
      );
    });

    test('按住并移动进入 dragging', () {
      expect(
        resolveBookmarkEntryState(isDragging: true, panelOpen: false),
        BookmarkEntryState.dragging,
      );
    });

    test('拖起后松手回 idle，吸附不改变状态结论', () {
      expect(
        resolveBookmarkEntryState(isDragging: false, panelOpen: false),
        BookmarkEntryState.idle,
      );
    });

    test('单击打开面板进入 active，关闭回 idle', () {
      expect(
        resolveBookmarkEntryState(isDragging: false, panelOpen: true),
        BookmarkEntryState.active,
      );
      expect(
        resolveBookmarkEntryState(isDragging: false, panelOpen: false),
        BookmarkEntryState.idle,
      );
    });

    test('面板打开时拖动仍以 dragging 优先', () {
      expect(
        resolveBookmarkEntryState(isDragging: true, panelOpen: true),
        BookmarkEntryState.dragging,
      );
    });
  });

  group('三态视觉参数', () {
    test('三态只差阴影与极小位移，不做缩放', () {
      final idle = ReaderUiConfig.entryStateStyle(BookmarkEntryState.idle);
      final dragging = ReaderUiConfig.entryStateStyle(
        BookmarkEntryState.dragging,
      );
      final active = ReaderUiConfig.entryStateStyle(BookmarkEntryState.active);

      expect(idle.hasShadow, isFalse);
      expect(idle.pullOffset, 0);

      expect(dragging.pullOffset, greaterThan(0));
      expect(dragging.pullOffset, lessThanOrEqualTo(4));
      expect(dragging.hasShadow, isTrue);

      expect(active.pullOffset, 0);
      expect(active.hasShadow, isTrue);
    });

    test('lerp 端点等于目标参数，中间值线性插值', () {
      final idle = ReaderUiConfig.entryStateStyle(BookmarkEntryState.idle);
      final dragging = ReaderUiConfig.entryStateStyle(
        BookmarkEntryState.dragging,
      );

      expect(BookmarkEntryStateStyle.lerp(idle, dragging, 0), idle);
      expect(BookmarkEntryStateStyle.lerp(idle, dragging, 1), dragging);

      final middle = BookmarkEntryStateStyle.lerp(idle, dragging, 0.5);
      expect(
        middle.pullOffset,
        closeTo((idle.pullOffset + dragging.pullOffset) / 2, 1e-9),
      );
      expect(
        middle.shadowOpacity,
        closeTo((idle.shadowOpacity + dragging.shadowOpacity) / 2, 1e-9),
      );
    });
  });
}
