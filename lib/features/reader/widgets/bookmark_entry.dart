import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../presentation/bookmark_entry_layout.dart';
import '../presentation/bookmark_entry_state.dart';
import '../presentation/reader_ui_config.dart';
import 'bookmark_entry_artwork.dart';

/// 阅读页侧边的书签入口：竖向条，贴着当前朝向的右侧边缘。
///
/// 视觉语义：静止与拖拽只露爪部，点击进入激活态后头部从侧边向外顶出
/// （带轻微回弹），素材分层与动效参数见 [BookmarkEntryArtwork] 与
/// [ReaderUiConfig]。
///
/// 交互：
/// - 按下即滑出；抬手时仍在入口区域内则 [onActivate] 打开面板，否则回弹折叠；
/// - 按住后可拖动，松手平滑吸附回右侧边，纵向位置取松手点；
/// - 拖动结束后不会误触打开面板；
/// - 视觉状态 idle / dragging / active 由 [resolveBookmarkEntryState] 统一推导，
///   过渡参数集中在 [ReaderUiConfig.entryStateVisuals]。
///
/// 尺寸上铺满整个阅读区，但只有入口矩形参与命中，空区域会让点击落回下层
/// 翻页层，因此不影响左右翻页点击区。
class BookmarkEntry extends StatefulWidget {
  const BookmarkEntry({
    super.key,
    required this.panelOpen,
    required this.onActivate,
    required this.layout,
    required this.initialRatio,
    required this.onSettled,
  });

  /// 面板是否打开：打开期间保持展开，关闭后回弹折叠。
  final bool panelOpen;

  /// 抬手仍在入口区域内时回调（打开书签面板）。
  final VoidCallback onActivate;

  /// 当前朝向的可用范围；朝向或尺寸变化时据此重新贴回右侧边。
  final BookmarkEntryLayout layout;

  /// 当前朝向记住的纵向比例；null 表示首次使用，贴右上角。
  final double? initialRatio;

  /// 吸附开始时回报落点比例，由上层按朝向持久化。
  final ValueChanged<double> onSettled;

  @override
  State<BookmarkEntry> createState() => _BookmarkEntryState();
}

class _BookmarkEntryState extends State<BookmarkEntry>
    with TickerProviderStateMixin {
  final GlobalKey _faceKey = GlobalKey();
  late final AnimationController _revealController;
  late final CurvedAnimation _reveal;
  late final AnimationController _snapController;
  late final AnimationController _stateController;

  /// 头部探出：只在激活态前进，其余状态回落到 0。
  late final AnimationController _headController;
  late final CurvedAnimation _headReveal;
  late final Listenable _positionListenable;

  /// 当前视觉状态；只影响视觉，不参与业务判断。
  late BookmarkEntryState _entryState;
  BookmarkEntryStateStyle _stateFrom = const BookmarkEntryStateStyle();
  BookmarkEntryStateStyle _stateTo = const BookmarkEntryStateStyle();

  /// 静止时的纵坐标；静止横坐标由布局的右侧边决定。
  late double _restTop;

  int? _activePointer;
  Offset _downPosition = Offset.zero;
  Offset _dragAnchor = Offset.zero;
  bool _dragging = false;

  /// 拖动中的实时位置；非拖动状态为 null。
  Offset? _dragPosition;

  /// 吸附动画的起止位置；不在吸附中时为 null。
  Offset? _snapFrom;
  Offset? _snapTo;

  /// 折叠/展开时藏在屏幕右侧的厚度。
  double get _thickness => ReaderUiConfig.entryThickness;

  @override
  void initState() {
    super.initState();
    _restTop = widget.layout.initialTop(widget.initialRatio);
    _revealController = AnimationController(
      vsync: this,
      duration: ReaderUiConfig.revealDuration,
      reverseDuration: ReaderUiConfig.collapseDuration,
    );
    _reveal = CurvedAnimation(
      parent: _revealController,
      curve: ReaderUiConfig.revealCurve,
      reverseCurve: ReaderUiConfig.collapseCurve,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: ReaderUiConfig.entrySnapDuration,
    )..addStatusListener(_onSnapStatus);
    _stateController = AnimationController(
      vsync: this,
      duration: ReaderUiConfig.entryStateTransitionDuration,
    );
    _headController = AnimationController(
      vsync: this,
      duration: ReaderUiConfig.entryHeadRevealDuration,
    );
    _headReveal = CurvedAnimation(
      parent: _headController,
      curve: ReaderUiConfig.entryHeadRevealCurve,
    );
    _entryState = resolveBookmarkEntryState(
      isDragging: false,
      panelOpen: widget.panelOpen,
    );
    _stateFrom = ReaderUiConfig.entryStateStyle(_entryState);
    _stateTo = _stateFrom;
    _stateController.value = 1;
    // 首次构建就可能处于激活态（例如从别处返回时面板仍打开），不留瞬变。
    _headController.value = _entryState == BookmarkEntryState.active ? 1 : 0;
    _positionListenable = Listenable.merge(<Listenable>[
      _reveal,
      _snapController,
      _stateController,
      _headController,
    ]);
  }

  @override
  void didUpdateWidget(covariant BookmarkEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.panelOpen != oldWidget.panelOpen) {
      if (widget.panelOpen) {
        _revealController.forward();
      } else if (!_snapController.isAnimating) {
        _revealController.reverse();
      }
      // 页面重建阶段直接改字段，build 紧随其后，无需再 setState。
      _syncEntryState(notify: false);
    }
    if (oldWidget.layout == widget.layout) return;

    // 旋转或窗口尺寸变化：中断手势与吸附，重新贴回新朝向的右侧边。
    _activePointer = null;
    _dragging = false;
    _dragPosition = null;
    _snapController.stop();
    _snapFrom = null;
    _snapTo = null;
    _syncEntryState(notify: false);
    final sameOrientation =
        oldWidget.layout.isLandscape == widget.layout.isLandscape;
    // 换朝向用新朝向记住的位置；同朝向只是尺寸变化时按比例保持。
    final ratio = sameOrientation
        ? oldWidget.layout.ratioOf(_restTop)
        : widget.initialRatio;
    _restTop = widget.layout.initialTop(ratio);
    if (!widget.panelOpen) _revealController.reverse();
  }

  @override
  void dispose() {
    _headController.dispose();
    _stateController.dispose();
    _snapController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  /// 当前插值出的视觉参数；过渡中从当前结果继续，避免快速切换时跳变。
  BookmarkEntryStateStyle _currentStateStyle() {
    final t = ReaderUiConfig.entryStateTransitionCurve.transform(
      _stateController.value,
    );
    return BookmarkEntryStateStyle.lerp(_stateFrom, _stateTo, t);
  }

  /// 状态只由手势事实与面板开关推导，迁移规则不散落在各事件里。
  void _syncEntryState({bool notify = true}) {
    final next = resolveBookmarkEntryState(
      isDragging: _dragging,
      panelOpen: widget.panelOpen,
    );
    if (next == _entryState) return;
    final from = _currentStateStyle();
    void apply() {
      _stateFrom = from;
      _stateTo = ReaderUiConfig.entryStateStyle(next);
      _entryState = next;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
    _stateController.forward(from: 0);
    // 只有激活态露头；idle / dragging 都回落到「只露爪」。
    if (next == BookmarkEntryState.active) {
      _headController.forward();
    } else {
      _headController.reverse();
    }
  }

  void _onSnapStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    setState(() {
      _restTop = _snapTo?.dy ?? _restTop;
      _snapFrom = null;
      _snapTo = null;
    });
    if (!widget.panelOpen) _revealController.reverse();
  }

  /// 静止时贴右侧边，纵向取 [_restTop]。
  Offset get _restPosition => Offset(widget.layout.right - _thickness, _restTop);

  /// 当前应绘制的位置：拖动中跟手，吸附中按曲线插值，否则贴边。
  Offset _visualPosition() {
    final dragPosition = _dragPosition;
    if (dragPosition != null) return dragPosition;
    final from = _snapFrom;
    final to = _snapTo;
    if (from != null && to != null) {
      final t = ReaderUiConfig.entrySnapCurve.transform(_snapController.value);
      return Offset.lerp(from, to, t) ?? to;
    }
    return _restPosition;
  }

  Offset _clampVisual(Offset position) {
    final maxLeft = (widget.layout.right - _thickness).clamp(
      0.0,
      double.infinity,
    );
    return Offset(
      position.dx.clamp(0.0, maxLeft).toDouble(),
      widget.layout.clampTop(position.dy),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        (event.buttons & kPrimaryButton) == 0) {
      return;
    }
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _downPosition = event.position;
    _revealController.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    final delta = event.position - _downPosition;
    if (!_dragging) {
      if (delta.distance < kTouchSlop) return;
      _dragging = true;
      // 若上一次吸附还没走完，从当前动画位置接着拖，避免跳变。
      final anchor = _visualPosition();
      _snapController.stop();
      _snapFrom = null;
      _snapTo = null;
      _restTop = widget.layout.clampTop(anchor.dy);
      _dragAnchor = Offset(anchor.dx, _restTop);
      _dragPosition = _clampVisual(_dragAnchor + delta);
      setState(() {});
      _syncEntryState();
      return;
    }
    setState(() {
      _dragPosition = _clampVisual(_dragAnchor + delta);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    if (_dragging) {
      _dragging = false;
      // 松手立即回 idle，位置吸附动画继续播放。
      _syncEntryState();
      _startSnap();
      return;
    }
    if (_isInsideEntry(event.position)) {
      widget.onActivate();
    } else if (!widget.panelOpen && !_snapController.isAnimating) {
      _revealController.reverse();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_activePointer != event.pointer) return;
    _activePointer = null;
    if (_dragging) {
      _dragging = false;
      _syncEntryState();
      _startSnap();
    } else if (!widget.panelOpen) {
      _revealController.reverse();
    }
  }

  /// 松手后吸附回右侧边：纵向取松手点，横向平滑回到贴边位置。
  void _startSnap() {
    final visual = _dragPosition ?? _visualPosition();
    final target = Offset(
      widget.layout.right - _thickness,
      widget.layout.clampTop(visual.dy),
    );
    _dragPosition = null;
    _restTop = target.dy;
    // 动画中途退出也不丢位置，先回报落点再播放动画。
    widget.onSettled(widget.layout.ratioOf(target.dy));
    if ((visual - target).distance < 0.5) {
      setState(() {});
      if (!widget.panelOpen) _revealController.reverse();
      return;
    }
    _snapFrom = visual;
    _snapTo = target;
    _snapController.forward(from: 0);
    setState(() {});
  }

  /// 用入口自身的 RenderBox 判断落点，自动带上折叠/展开位移。
  bool _isInsideEntry(Offset globalPosition) {
    final box = _faceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (Offset.zero & box.size).contains(box.globalToLocal(globalPosition));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _positionListenable,
      builder: (context, child) {
        final position = _visualPosition();
        // 折叠时把入口厚度的一半藏到屏幕右侧，按下滑出。
        final hiddenRatio =
            (1 - ReaderUiConfig.collapsedVisibleRatio) * (1 - _reveal.value);
        final style = _currentStateStyle();
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: position.dx + hiddenRatio * _thickness,
              top: position.dy,
              width: _thickness,
              height: ReaderUiConfig.entryLength,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: ReaderUiConfig.entryInnerRadius,
                  boxShadow: style.hasShadow
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: style.shadowOpacity,
                            ),
                            blurRadius: style.shadowBlur,
                            offset: style.shadowOffset,
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: child!,
              ),
            ),
          ],
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: SizedBox(
            key: _faceKey,
            width: _thickness,
            height: ReaderUiConfig.entryLength,
            child: Semantics(
              button: true,
              label: '书签',
              // 旋转角度由贴边方向决定：素材顶端始终朝向屏幕外侧。
              // 彩色图不染色；入口形状只裁内侧两角。
              child: ClipRRect(
                borderRadius: ReaderUiConfig.entryInnerRadius,
                child: RotatedBox(
                  quarterTurns: ReaderUiConfig.entryQuarterTurns,
                  child: AnimatedBuilder(
                    animation: _positionListenable,
                    builder: (context, _) => BookmarkEntryArtwork(
                      headReveal: _headReveal.value,
                      pullOffset: _currentStateStyle().pullOffset,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
