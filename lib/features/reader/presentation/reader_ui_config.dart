import 'package:flutter/material.dart';

import 'bookmark_entry_state.dart';

/// 入口贴边的哪一侧；旋转角度、圆角方向都由它推导。
enum BookmarkEntrySide { right, left }

/// 阅读页书签入口与面板的 UI 参数。
///
/// 尺寸、时长、曲线、颜色、资源路径集中在这里，组件只读取，方便按手感微调。
abstract final class ReaderUiConfig {
  // ---- 阅读区配色 ----

  /// 阅读区底色：页面按宽度适配后上下留白的区域。夜间模式在这里切换。
  static const Color readerBackgroundColor = Color(0xFFFFFFFF);

  /// 阅读区前景色：错误提示、渲染失败提示，与 [readerBackgroundColor] 配套。
  static const Color readerForegroundColor = Color(0xDD212121);

  /// EPUB 正文颜色；标题更深，引用与代码更浅。
  static const Color epubTextColor = Color(0xE6212121);
  static const Color epubQuoteColor = Color(0xCC5F5F5F);
  static const Color epubDividerColor = Color(0x33212121);

  // ---- 入口尺寸与形状 ----

  /// 展开态入口长度（dp），沿屏幕侧边方向；素材横向 132 旋转 90° 后即为此长度。
  static const double entryLength = 132;

  /// 入口厚度（dp），垂直侧边方向；折叠时露出的厚度 = 该值 ×
  /// [collapsedVisibleRatio]。
  static const double entryThickness = 40;

  /// 入口圆角半径（dp），只作用于靠屏幕内侧的两角（贴边一侧为直角）。
  static const double entryCornerRadius = 12;

  /// 折叠态露出的厚度占展开厚度的比例。
  ///
  /// 入口改为「静止只露爪、激活才露头」后不再靠折叠藏头，默认完整贴边（1.0）；
  /// 参数保留，需要恢复「露出一半、按下再滑出」时改回 0.5 即可。
  static const double collapsedVisibleRatio = 1;

  // ---- 入口图资源 ----

  /// 入口图（彩色猫图标）。用 3x 资源，桌面与移动端共用，不做任何染色。
  /// 绘制时整体旋转 90°，贴侧边呈竖向条；素材顶端朝屏幕外侧。
  static const String entryAssetPath = 'assets/images/bookmark/cat-icon@3x.png';

  /// 资源缺失时代码绘制占位形状的填充色。
  static const Color entryPlaceholderColor = Color(0xE62E2E2E);

  // ---- 入口贴边方向 ----

  /// 入口贴哪一侧。右侧为当前方案；左侧为预留，吸附与面板逻辑同样适用。
  static const BookmarkEntrySide entrySide = BookmarkEntrySide.right;

  /// 素材整体旋转角度：让素材「顶端」朝向屏幕外侧。
  ///
  /// - 贴右边：顺时针 90°（`quarterTurns = 1`），顶端朝右 = 屏幕外；
  /// - 贴左边：逆时针 90°（`quarterTurns = 3`），顶端朝左 = 屏幕外。
  ///
  /// 旋转与锚边绑定，不写死在组件里，换边只改 [entrySide]。
  static int get entryQuarterTurns =>
      entrySide == BookmarkEntrySide.right ? 1 : 3;

  /// 入口内侧两角的圆角：贴右边时在左侧，贴左边时在右侧。
  static BorderRadius get entryInnerRadius =>
      entrySide == BookmarkEntrySide.right
      ? const BorderRadius.horizontal(
          left: Radius.circular(entryCornerRadius),
        )
      : const BorderRadius.horizontal(
          right: Radius.circular(entryCornerRadius),
        );

  // ---- 入口素材位移（静止只露爪，激活收回到完整可见）----

  /// 静止态把整张素材沿屏幕外法线方向推出去的厚度占入口厚度的比例。
  ///
  /// 0.72 表示推出 40 × 0.72 ≈ 29 dp：头部被推出屏幕，屏内只剩素材底部约
  /// 28%（爪部）扒在边上。激活态该位移归零，整张素材回到入口内。
  static const double entryStaticOutwardRatio = 0.72;

  /// 顶出 / 回落时长与曲线；`easeOutBack` 收尾轻微超调，形成回弹。
  static const Duration entryHeadRevealDuration = Duration(milliseconds: 280);
  static const Curve entryHeadRevealCurve = Curves.easeOutBack;

  // ---- 入口动效 ----

  /// 按下即滑出，先快后缓。
  static const Duration revealDuration = Duration(milliseconds: 200);
  static const Curve revealCurve = Curves.easeOutCubic;

  /// 抬手移出区域后回弹折叠。
  static const Duration collapseDuration = Duration(milliseconds: 160);
  static const Curve collapseCurve = Curves.easeOutCubic;

  /// 拖动松手后吸附回右侧边的时长与曲线；纵向取松手点，主要动的是横向。
  static const Duration entrySnapDuration = Duration(milliseconds: 260);
  static const Curve entrySnapCurve = Curves.easeOutCubic;

  // ---- 入口三态视觉 ----

  /// 三态之间只允许阴影与极小位移差，不使用缩放、旋转或非等比拉伸。
  ///
  /// 参数集中放在此表，后期某一态要调手感只改这里。
  /// [BookmarkEntryStateStyle.pullOffset] 只给拖拽态，形成「被拉扯」的轻微外移。
  static const Map<BookmarkEntryState, BookmarkEntryStateStyle>
  entryStateVisuals = <BookmarkEntryState, BookmarkEntryStateStyle>{
    BookmarkEntryState.idle: BookmarkEntryStateStyle(),
    BookmarkEntryState.dragging: BookmarkEntryStateStyle(
      shadowBlur: 16,
      shadowOpacity: 0.22,
      shadowOffset: Offset(-6, 0),
      pullOffset: 2,
    ),
    BookmarkEntryState.active: BookmarkEntryStateStyle(
      shadowBlur: 12,
      shadowOpacity: 0.16,
      shadowOffset: Offset(-4, 0),
    ),
  };

  static BookmarkEntryStateStyle entryStateStyle(BookmarkEntryState state) =>
      entryStateVisuals[state]!;

  /// 三态之间的过渡：切换时从当前插值结果继续，不瞬变。
  static const Duration entryStateTransitionDuration = Duration(
    milliseconds: 180,
  );
  static const Curve entryStateTransitionCurve = Curves.easeOutCubic;

  // ---- 书签面板 ----

  /// 面板从右侧横向滑入 / 滑出。
  static const Duration panelOpenDuration = Duration(milliseconds: 250);
  static const Curve panelOpenCurve = Curves.easeOutCubic;
  static const Duration panelCloseDuration = Duration(milliseconds: 200);
  static const Curve panelCloseCurve = Curves.easeInCubic;

  /// 面板最大宽度占屏幕宽度的比例。
  static const double panelMaxWidthRatio = 0.85;

  /// 面板最大宽度（dp），横屏/桌面不被拉成整屏宽。
  static const double panelMaxWidth = 420;

  /// 面板右边缘与入口内边缘对齐：右侧让出一条入口厚度，入口保持可见。
  static const double panelSideOffset = entryThickness;

  /// 面板圆角半径（dp），只作用于靠屏幕内侧（左侧）的两角。
  static const double panelCornerRadius = 20;

  /// 面板打开时遮罩的最大不透明度。
  static const double panelScrimOpacity = 0.35;
}
