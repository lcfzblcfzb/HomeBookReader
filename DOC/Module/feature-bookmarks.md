# 模块：书签（features/bookmarks）

- 目录：`lib/features/bookmarks/{presentation,application}`
- 所属层：presentation + application
- 状态：M1 基础列表；M3 第一轮面板增加「目录」页签；M1-016 增加「排版」页签与 EPUB 位置书签；M1-017 头部增加「书架」按钮

## 职责

1. 书签模式面板：由阅读页右侧边可上下拖动、带 idle/dragging/active 三态视觉的书签入口唤起，覆盖在阅读页上层的浮层，从右侧横向滑入/滑出。
2. 基础列表：按位置展示已添加书签（页码 / 位置百分比 + 标签 + 摘录），点击跳转：
   PDF 跳页，EPUB 按 `position` 换算章与字符偏移。
3. 面板头部以轻量页签承载「书签 / 目录」，EPUB 另有「排版」；头部动作区含
   「当前页/当前位置」（加书签）、「书架」（M1-017，返回书架）与「关闭」；
   目录内容由 `features/toc` 提供，排版内容由独立的 `TypographySettingsPanel` 提供；
   不新增阅读页常驻控件。
4. 本轮只做「入口 + 基础列表」；新增/改名/删除/去重规则（D4）留待 M4 细化。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `BookmarkPanel` | 书签模式浮层面板（右侧滑入的侧边面板；页签 + 书签列表 + 目录列表 + 可选排版页，可关闭，可经 `onGoToBookshelf` 返回书架） |
| `BookmarksController` | `list(documentId)`、`jumpTo(bookmark)`、`close()` |
| `BookmarkTile` | 单条书签展示（页码或位置百分比） |
| `TypographySettingsPanel` | 独立排版设置组件（字号 5 档 / 行距 2 档），只依赖 `value` + `onChanged`，便于从面板搬走 |

## 依赖关系

- 依赖：`data/repos: BookmarkRepository`、`features/reader`（跳转 / 位置 / 当前章回调）、`app/theme`
- 被依赖：`features/reader`（作为书签模式内容）
- 禁止：自行打开 PDF 或读写文件；不直接访问 DAO。

## 约束

- 面板出现时阅读层保持原页不变，关闭后回到同一页。
- 面板形态：覆盖在阅读页上的浮层，从右侧横向滑入；右边缘让出入口厚度（`ReaderUiConfig.panelSideOffset`），入口保持可见且不被遮罩压暗；宽度 `min(屏宽 × 0.85, 420 dp, 可用宽度)`，内侧（左）两角圆角，`SafeArea` 保留上/下/左。不新增阅读页常驻控件。
- 空列表给出中文提示，不显示错误态；EPUB 文案为「当前位置还没有书签」。
- 跳转后自动关闭面板并更新阅读位置；PDF 用 `page_index`，EPUB 用 `position`，两者互不写入对方的字段。
- 「排版」页签仅在会话声明 `supportsTypography` 时出现（PDF 不显示）。
- 「书架」按钮（M1-017）：任意页签下可见，紧凑密度与「当前页/当前位置」按钮同规格；
  点击只回调 `onGoToBookshelf`（由 `ReaderShell` 统一 `context.go('/')`），
  面板随路由离开自动消亡，不自行关面板或落进度。

## 验证

- 组件测试：空态、列表排序、跳转回调触发；Windows 冒烟：打开面板 → 跳转 → 关闭。
- EPUB：`test/features/reader/epub_reader_controller_test.dart` 覆盖加位置书签 → 跳走 → 跳回、
  退出重进恢复；`test/data/db/migration_test.dart` 覆盖 `page_index = null` + `position` 落库。
- 排版页签与面板内字号 / 行距切换的真机交互待复核。
- 返回书架（M1-017）：`test/features/reader/reader_shell_test.dart` 覆盖面板「书架」按钮
  回调到路由跳转；Windows 集成冒烟见 [feature-reader](./feature-reader.md)。
