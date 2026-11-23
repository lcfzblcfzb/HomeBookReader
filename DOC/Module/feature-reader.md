# 模块：阅读器（features/reader）

- 目录：`lib/features/reader/{presentation,application,widgets}`
- 所属层：presentation + application
- 状态：M0 骨架 / M1 单页翻页 / M3 第一轮面板目录页签 / M1-010 入口拖拽吸附与位置记忆 / M1-012 入口手势排除区 / M1-013 入口改侧边吸附 / M1-014 爪/头两态视觉 / M1-015 PDF 与 EPUB 导入 / M1-016 抽出公共外壳并支持 EPUB 分页阅读 / M1-017 Esc 与面板「书架」按钮返回书架

## 职责

1. 阅读模式：全屏展示当前页，无任何常驻工具栏。PDF 单页展示，按宽度适配后上下留白；
   EPUB 按可用宽高、字号、行距分页。两者共用 `ReaderShell`（沉浸式、书签入口、面板、返回键）。
   EPUB 只改文档文件，不经过 PDF 引擎；详见 [feature-epub-reader](./feature-epub-reader.md)。
2. 翻页：点击屏幕左侧 1/3 为上一页、右侧 1/3 为下一页，中间不响应；PDF 首末页边界无动作，
   EPUB 跨章连续翻到全书末尾给「已到全书末尾」提示。
3. 侧边书签入口：竖向条，贴**当前朝向的右侧边缘**（竖屏贴长边、横屏贴短边），初始贴右上角；可上下拖动，松手平滑吸附回右侧边，纵向位置按朝向分别记忆。视觉语义为「静止只露爪、激活才露头」：同一张素材按 `BoxFit.contain` 等比绘制（源图 96×96 → 40×40 dp），三态只差整体位移——idle / dragging 沿屏幕外法线推出约 29 dp 只露爪部，面板打开（active）时位移归零、头部露出并带轻微回弹；不做缩放、倾斜、非等比拉伸或裁剪。素材是彩色猫图标（`assets/images/bookmark/cat-icon@3x.png`，不染色），资源缺失时回退为深色圆角占位。
4. 阅读进度：PDF 加载时恢复 `page_index`，翻页后节流保存；EPUB 恢复 / 保存 `position`（0–1）。
5. 书签模式承载：书签面板浮在页面上层，作为阅读页内部状态；面板从入口所在侧边（右侧）横向滑入，内含「书签 / 目录」两个页签，EPUB 额外提供「排版」页签。目录数据由 `TocRepository` 提供，打开文档后在后台解析，不阻塞首屏。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `ReaderHostPage(documentId)` | 阅读页路由目标；按 `documents.format` 选择 PDF / EPUB 页 |
| `ReaderPage(documentId)` | PDF 阅读页，创建 `ReaderController` |
| `EpubReaderPage(documentId)` | EPUB 分页阅读页，创建 `EpubReaderController` |
| `ReaderShell` | 公共外壳：沉浸式、右入口、面板动画、返回键、Esc 返回书架、面板「书架」按钮接线、加载/错误态；`bodyBuilder` + 可选 `typographyBuilder` |
| `ReaderSession` | 外壳依赖的会话接口：加载/错误、面板状态、书签/目录、翻页、跳转、进度保存 |
| `ReaderPanelTab` | `bookmarks` / `toc` / `typography`（PDF 不显示排版页签） |
| `ReaderController` | PDF：`pageIndex`、`pageCount`、翻页、目录跳页、页码书签 |
| `EpubReaderController` | EPUB：`currentPage`、`position`、`setViewport`、`setTypography`、跨章翻页 |
| `ReaderMode` | `reading` / `bookmarks` 枚举（书签模式不占路由） |
| `PageTurnLayer` | 左右分区的点击层，中间区不绑定动作 |
| `BookmarkEntry` | 侧边书签入口（旋转竖向、拖动/吸附/三态视觉/吃掉自身手势） |
| `BookmarkEntryArtwork` | 入口素材绘制：整图 `BoxFit.contain` 等比显示 + 外法线位移，`headReveal` 控制推出量、`pullOffset` 为拖拽额外外移；无缩放/裁剪 |
| `BookmarkEntryLayout` | 入口在当前朝向下的右侧边位置、纵向可用范围与比例换算/clamp |
| `BookmarkEntryState` / `BookmarkEntryStateStyle` | 三态枚举、状态推导与单态视觉参数（阴影 / `pullOffset`，不含缩放/旋转/拉伸）及插值 |
| `ReaderUiConfig` | 入口长度/厚度/圆角、贴边侧与旋转/圆角推导、折叠比例、静止推出比例、露出时长曲线 `pullOffset`、吸附参数、三态视觉表、面板侧边参数、EPUB 文字/引用/分隔线颜色集中配置 |
| `SystemGestureExclusionService` | Android 手势排除区上报/清空；非 Android 为空操作 |

## 依赖关系

- 依赖：`data/repos`（Document / Progress / Bookmark / Toc / ReaderEntryPosition / ReaderTypography）、`core/pdf`（渲染 + 页尺寸）、`core/ebook`（EPUB 会话 / 内容 / 排版参数）、`core/platform`（系统手势排除区）、`app/theme`
- 被依赖：`app/router`；`features/bookmarks` 以浮层面板形式嵌入本页
- 禁止：自行调用 `pdfrx`；自行拼绝对路径。

## 约束

- 翻页为瞬时切换，无滑动/仿真动画；不给页码常驻控件。
- 返回键：书签模式开启时先关闭面板，否则回书架。
- Esc（Windows 替代返回键，M1-017）：外壳 `CallbackShortcuts(escape)` + `Focus(autofocus)`，
  面板打开先关面板、面板关闭 `context.go('/')` 回书架，与返回键行为一致；键盘事件沿
  焦点链冒泡，正文有焦点节点时同样生效。面板「书架」按钮（`onGoToBookshelf`）为三端
  通用显式入口，返回统一走 `context.go('/')`，进度落库与沉浸式恢复照常。
- 系统栏：进入阅读页隐藏状态栏与导航栏（immersive），退出恢复。
- 书签面板：覆盖在阅读页上的浮层，从**右侧**横向滑入/滑出（`ClipRect` + `FractionalTranslation`）；右边缘让出 `panelSideOffset`（= 入口厚度），入口保持可见、不被遮罩压暗；宽度 `min(屏宽 × 0.85, 420 dp, 可用宽度)`，内侧（左）两角圆角，`SafeArea` 保留上/下/左。遮罩点击与返回键关闭逻辑不变，不新增常驻控件。
- 书签入口：竖向条贴当前朝向右侧边，`RotatedBox` 的 `quarterTurns` 由 `ReaderUiConfig.entrySide` 推导（右 = 1，左 = 3），保证素材「顶端」朝屏幕外侧；铺满阅读区但只有入口矩形命中，空区域透传给下层翻页层，右边缘 40 dp 宽度以外的左右 1/3 点击翻页不受影响。拖动位置 clamp 在 `MediaQuery.padding` 安全区内；松手只沿右侧边落位，纵向用 `entrySnapDuration` 平滑吸附；旋转或窗口尺寸变化时按新朝向重新贴边；竖屏/横屏位置分别存 `app_meta`（`reader.entry_y.portrait` / `reader.entry_y.landscape`），存 0..1 比例。旧键 `reader.entry_x.*`（贴顶时期横坐标）在读取时删除，不参与计算。
- 素材两态：`BookmarkEntryArtwork` 只画一张整图，按 `BoxFit.contain` 等比显示（源图 96×96 → 绘制 40×40 dp，比例 1:1），用整体平移表达两态——静止沿屏幕外法线推出 `entryThickness × entryStaticOutwardRatio`（≈29 dp），屏内只剩底部爪部；激活位移归零，头部露出，`Curves.easeOutBack` 收尾轻微回弹。位移由 `Transform.translate` 承担，`Stack(clipBehavior: Clip.none)` 允许素材部分移出可视区而不被内部布局裁掉，不使用裁剪、缩放或非等比拉伸；拖拽态在静止位移上再加 `pullOffset`（2 dp）。时长/曲线/比例均为配置项；后续换成「只含爪子的图 / 单独的头」时改为两层叠加，共用同一露出进度，状态机与动效参数不变。入口命中区始终是 `entryThickness × entryLength`（40×132 dp），不随素材大小变化。素材出图规格（比例、像素、透明边、分层）见[书签素材设计规范](../书签素材设计规范.md)。
- 侧边返回手势（Android）：入口竖向矩形（`entryThickness × entryLength`）通过原生通道 `homepdfreader/gesture_exclusion` 报到 `setSystemGestureExclusionRects`；系统左右边按 200 dp 高度计预算，入口 132 dp 一条即可容纳。入口首次可见、吸附落点变化、转屏、面板开关时重报（矩形 + 朝向 + 面板状态去重），离开阅读页清空。已实测入口内横向滑动不触发返回、入口外滑动正常返回。
- 入口三态：`idle` / `dragging` / `active` 由 `resolveBookmarkEntryState(isDragging, panelOpen)` 唯一推导；原地按住不移动不进入 dragging，拖动松手立即回 idle（吸附保留），面板开关驱动 active/idle；过渡由单一 `AnimationController`（`entryStateTransitionDuration`）插值 `entryStateVisuals`（阴影 + `pullOffset`，不含缩放/旋转/拉伸）。头部露出由独立 `_headController` 驱动，仅 active 前进，idle/dragging 回落。
- 文档格式：`documents.format == 'pdf'` 走 PDF 页；`'epub'` 走分页页。EPUB 不调用 PDF 引擎；
  进度写 `position`，不用 `page_index`。
- 单页模式下 `offset_y` 恒为 0，但字段保留。
- PDF 目录项落库为文档内部 0 基页码，跳转直接使用该值；EPUB 目录项用 `href + fragment`，
  由 `EpubReaderController` 换算成章内字符偏移；界面显示页码时才 +1。
- 渲染失败显示占位与重试，不崩溃；文件缺失回书架并提示。
- EPUB 启动只解析包与目录；正文按章懒解析、逐页排版，缓存 3 章；定位期间显示加载态，
  不显示章首残页。

## 验证

- 格式分流：`ReaderHostPage` 按 `format` 选择页面；PDF 用例仍全过（63 条）。
- 组件测试：左右分区命中、首末页边界、书签模式进出；入口初始贴右侧边、点击打开面板、纵向拖动吸附、旋转按横屏位置重锚定、三态仅位移差异（静止 -28.8 dp / 拖拽 +2 dp / 激活 0）、idle/dragging 不露头 + active 露头、关闭回落（`test/features/reader/bookmark_entry_test.dart`）；布局比例与 clamp（`bookmark_entry_layout_test.dart`）；状态迁移与视觉参数插值（`bookmark_entry_state_test.dart`）；排除区预算裁剪（`test/core/platform/system_gesture_exclusion_test.dart`）。Windows 冒烟：打开样本翻到末页再返回。
- 集成：`integration_test/m1_smoke_test.dart` 覆盖目录加载；模拟器核实目录列出、当前章高亮、点击跳页、空态与缓存命中。
- EPUB 集成：`test/features/reader/epub_reader_controller_test.dart` 用真实 EPUB 覆盖翻页、跨章、
  末尾提示、目录 fragment 跳转、书签往返、退出重进恢复、字号重排、横竖屏切换。
- 模拟器核实入口竖屏贴右侧、拖动吸附、重进沿用；横屏贴短边、转屏后按各自位置重贴；面板从右侧滑入；idle / dragging / active 三态与过渡。
- 模拟器核实侧边返回手势：入口矩形内横向滑动不触发返回，入口外侧滑动正常返回；手势导航下竖向拖动入口仍有效。
- 模拟器核实两态视觉：静止只露爪、点击后头部顶出；面板关闭后头部收回。
- EPUB 真机/模拟器复核：Pixel 5 API 30 上导入、翻页分区、目录跳转、返回键、字号重排、
  横竖屏与退出重进均通过；真机字体观感与手势返回待复核。
- 返回书架（M1-017）：组件测试 `reader_shell_test.dart` 覆盖 Esc 关面板 / Esc 回书架 /
  面板按钮回书架；Windows 集成冒烟 `m1_reader_return_smoke_test.dart`（真实窗口 +
  真实键盘事件）通过。注意：本机 flutter test 拉起的 App 进程拒绝写 AppData/Temp，
  既有 `m1_smoke_test` 同样受阻，属环境限制，完整导入链路冒烟留待用户终端手工复核。
