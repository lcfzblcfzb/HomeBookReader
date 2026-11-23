import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/platform/system_gesture_exclusion.dart';
import '../../../core/utils/app_logger.dart';
import '../../bookmarks/presentation/bookmark_panel.dart';
import '../application/reader_session.dart';
import '../widgets/bookmark_entry.dart';
import 'bookmark_entry_layout.dart';
import 'reader_ui_config.dart';

/// 阅读页公共外壳：沉浸式、右侧书签入口、面板滑入、返回键与错误态。
///
/// PDF 与 EPUB 只负责提供 [session] 与正文 [bodyBuilder]；面板里的
/// 「排版」页签通过 [typographyBuilder] 注入，PDF 不提供。
class ReaderShell extends ConsumerStatefulWidget {
  const ReaderShell({
    super.key,
    required this.session,
    required this.bodyBuilder,
    this.typographyBuilder,
  });

  final ReaderSession session;
  final WidgetBuilder bodyBuilder;

  /// 返回「排版」页签内容；为 null 时不显示该页签。
  final Widget Function(BuildContext context, ReaderSession session)?
  typographyBuilder;

  @override
  ConsumerState<ReaderShell> createState() => _ReaderShellState();
}

class _ReaderShellState extends ConsumerState<ReaderShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _panelController;
  late final Animation<double> _panelAnimation;
  late final SystemGestureExclusionService _gestureExclusion;

  /// 书签入口的纵向位置记忆：键为是否横屏，值为 0..1 的比例。
  final Map<bool, double?> _entryRatios = <bool, double?>{};
  bool _entryPositionsLoaded = false;

  Rect? _reportedExclusionRect;
  bool? _reportedLandscape;
  bool? _reportedPanelOpen;

  ReaderSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _gestureExclusion = ref.read(systemGestureExclusionProvider);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _panelController = AnimationController(
      vsync: this,
      duration: ReaderUiConfig.panelOpenDuration,
      reverseDuration: ReaderUiConfig.panelCloseDuration,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: ReaderUiConfig.panelOpenCurve,
      reverseCurve: ReaderUiConfig.panelCloseCurve,
    );
    _session.addListener(_onSessionChanged);
    _syncPanelAnimation();
    unawaited(_loadEntryPositions());
  }

  Future<void> _loadEntryPositions() async {
    final repository = ref.read(readerEntryPositionRepositoryProvider);
    double? portrait;
    double? landscape;
    try {
      portrait = await repository.load(isLandscape: false);
      landscape = await repository.load(isLandscape: true);
    } catch (error) {
      AppLogger.log(
        '书签入口位置读取失败',
        level: 'WARN',
        tag: 'READER',
        detail: '$error',
      );
    }
    if (!mounted) return;
    setState(() {
      _entryRatios[false] = portrait;
      _entryRatios[true] = landscape;
      _entryPositionsLoaded = true;
    });
  }

  void _onSessionChanged() {
    _syncPanelAnimation();
    final message = _session.takeTransientMessage();
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });
  }

  /// 面板开关由会话状态驱动，动画只跟随，不反向改状态。
  void _syncPanelAnimation() {
    if (_session.bookmarksVisible) {
      _panelController.forward();
    } else if (_panelController.value > 0) {
      _panelController.reverse();
    }
  }

  void _onEntrySettled({required bool isLandscape, required double ratio}) {
    if (_entryRatios[isLandscape] == ratio) return;
    setState(() => _entryRatios[isLandscape] = ratio);
    unawaited(
      ref
          .read(readerEntryPositionRepositoryProvider)
          .save(isLandscape: isLandscape, ratio: ratio)
          .catchError((Object error) {
            AppLogger.log(
              '书签入口位置保存失败',
              level: 'WARN',
              tag: 'READER',
              detail: '$error',
            );
          }),
    );
  }

  BookmarkEntryLayout _entryLayout(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.padding;
    final minTop = safe.top;
    final maxTop = (media.size.height - safe.bottom - ReaderUiConfig.entryLength)
        .clamp(minTop, double.infinity)
        .toDouble();
    return BookmarkEntryLayout(
      isLandscape: media.orientation == Orientation.landscape,
      // 竖屏贴长边、横屏贴短边，两者都是屏幕物理右侧。
      right: media.size.width - safe.right,
      minTop: minTop,
      maxTop: maxTop,
    );
  }

  /// 把入口当前矩形报给 Android 系统手势排除区。
  void _reportGestureExclusion(
    BookmarkEntryLayout layout, {
    required bool panelOpen,
  }) {
    if (!_gestureExclusion.isSupported) return;
    final screen = MediaQuery.sizeOf(context);
    final rect = Rect.fromLTWH(
      layout.right - ReaderUiConfig.entryThickness,
      layout.initialTop(_entryRatios[layout.isLandscape]),
      ReaderUiConfig.entryThickness,
      ReaderUiConfig.entryLength,
    );
    if (rect == _reportedExclusionRect &&
        layout.isLandscape == _reportedLandscape &&
        panelOpen == _reportedPanelOpen) {
      return;
    }
    _reportedExclusionRect = rect;
    _reportedLandscape = layout.isLandscape;
    _reportedPanelOpen = panelOpen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_gestureExclusion.setRects(<Rect>[rect], screenSize: screen));
    });
  }

  Future<void> _addBookmark() async {
    await _session.addBookmark();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('已添加书签')));
  }

  /// Esc：面板打开先关面板，否则回书架，与安卓返回键行为一致。
  void _onEscape() {
    if (_session.bookmarksVisible) {
      _session.closeBookmarks();
      return;
    }
    context.go('/');
  }

  @override
  void dispose() {
    unawaited(_gestureExclusion.clear());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(_session.flushProgress());
    _session.removeListener(_onSessionChanged);
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, child) {
        final bookmarksVisible = _session.bookmarksVisible;
        final ready = !_session.loading && _session.errorMessage == null;
        final entryLayout = _entryLayout(context);
        final entryVisible = ready && _entryPositionsLoaded;
        if (entryVisible) {
          _reportGestureExclusion(entryLayout, panelOpen: bookmarksVisible);
        }
        return PopScope(
          canPop: !bookmarksVisible,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _session.closeBookmarks();
          },
          // Windows 桌面没有系统返回键：Esc 兜住返回书架，行为与返回键一致。
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: ReaderUiConfig.readerBackgroundColor,
                body: Stack(
                  children: <Widget>[
                    Positioned.fill(child: _buildContent(context)),
                    if (entryVisible) _buildBookmarkOverlay(),
                    if (entryVisible)
                      Positioned.fill(
                        child: BookmarkEntry(
                          panelOpen: bookmarksVisible,
                          layout: entryLayout,
                          initialRatio: _entryRatios[entryLayout.isLandscape],
                          onActivate: _session.openBookmarks,
                          onSettled: (ratio) => _onEntrySettled(
                            isLandscape: entryLayout.isLandscape,
                            ratio: ratio,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_session.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _session.errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline,
                color: ReaderUiConfig.readerForegroundColor,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReaderUiConfig.readerForegroundColor,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go('/'),
                child: const Text('返回书架'),
              ),
            ],
          ),
        ),
      );
    }
    return widget.bodyBuilder(context);
  }

  Widget _buildBookmarkOverlay() {
    final typography = widget.typographyBuilder?.call(context, _session);
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        final progress = _panelAnimation.value;
        if (!_session.bookmarksVisible && _panelController.value == 0) {
          return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
        }
        final media = MediaQuery.of(context);
        final safe = media.padding;
        final rightInset = safe.right + ReaderUiConfig.panelSideOffset;
        final available = media.size.width - safe.left - rightInset;
        final width = (media.size.width * ReaderUiConfig.panelMaxWidthRatio)
            .clamp(0.0, ReaderUiConfig.panelMaxWidth)
            .clamp(0.0, available.clamp(0.0, double.infinity))
            .toDouble();
        return Positioned.fill(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _session.closeBookmarks,
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: ReaderUiConfig.panelScrimOpacity * progress,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: rightInset,
                width: width,
                child: ClipRect(
                  child: FractionalTranslation(
                    translation: Offset(1 - progress, 0),
                    child: BookmarkPanel(
                      tab: _session.panelTab,
                      onTabChanged: _session.selectPanelTab,
                      bookmarks: _session.bookmarkItems,
                      onClose: _session.closeBookmarks,
                      onGoToBookshelf: () => context.go('/'),
                      onAdd: () => unawaited(_addBookmark()),
                      onJump: (bookmark) {
                        _session.closeBookmarks();
                        unawaited(_session.jumpToBookmark(bookmark));
                      },
                      onDelete: (bookmark) =>
                          unawaited(_session.removeBookmark(bookmark.id)),
                      bookmarkLocation: _session.bookmarkLocation,
                      tocEntries: _session.tocItems,
                      tocLoading: _session.tocLoading,
                      tocError: _session.tocError,
                      hasTextLayer: _session.hasTextLayer,
                      onJumpEntry: (entry) {
                        _session.closeBookmarks();
                        unawaited(_session.jumpToTocEntry(entry));
                      },
                      isCurrentEntry: _session.isTocEntryCurrent,
                      tocEntryLocation: _session.tocEntryLocation,
                      typographyPanel: typography,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
