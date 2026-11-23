import 'package:flutter/material.dart';

/// 阅读页点击分区：左侧 1/3 上一页，右侧 1/3 下一页，中间不响应。
enum PageTurnZone { previous, middle, next }

class PageTurnLayer extends StatelessWidget {
  const PageTurnLayer({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  static PageTurnZone zoneOf(double dx, double width) {
    if (width <= 0) return PageTurnZone.middle;
    final ratio = dx / width;
    if (ratio < 1 / 3) return PageTurnZone.previous;
    if (ratio > 2 / 3) return PageTurnZone.next;
    return PageTurnZone.middle;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            switch (zoneOf(details.localPosition.dx, constraints.maxWidth)) {
              case PageTurnZone.previous:
                onPrevious();
              case PageTurnZone.next:
                onNext();
              case PageTurnZone.middle:
                break;
            }
          },
          child: child,
        );
      },
    );
  }
}
