# M1-016 EPUB 支持第二步：分页阅读页 TODO

> 依据：[开发大纲](../开发大纲.md) M1 阅读页 / M3 阅读面板
> 状态：已完成（单元/集成测试 + Android 模拟器手工复核通过）
> 范围：EPUB2 / EPUB3 分页阅读页（**不做滚动**）；交互与 PDF 阅读页一致。
> 明确不做：划线 / 批注、全文搜索、翻页动画特效、双栏。

## 1. 目标

1. 点屏幕左侧 1/3 翻上一页、右侧 1/3 翻下一页，中间不翻页；跨章节连续翻页，
   全书末尾给明确提示（SnackBar「已到全书末尾」）。
2. 右侧书签入口、书签面板、返回键行为与 PDF 完全一致：
   - 位置记忆、三态、面板从同侧滑入；
   - 面板「书签 / 目录」对 EPUB 可用；
   - 目录条目按 `href + fragment` 跳到排版结果的第一页；
   - 返回键先关面板再退出。
3. 排版：按当前可用宽高、字号、行距、页边距切页；标题层级、段首缩进与段间距、
   图片等比缩放居中、列表、引用、粗斜体。
4. 字号 5 档、行距 2 档、页边距 1 档默认值；改字号整本重排，当前阅读位置落回同一段文字。
5. 进度存 `position`（0–1），跨字号、屏幕尺寸、横竖屏恢复到同一处；书架显示百分比。
6. 性能：启动不排整本；按章节懒排版并缓存；单章渐进排版；翻页不明显卡顿。
7. 设置入口：书签面板新增「排版」页签，内容做成独立组件，便于以后搬走。

## 2. 方案

### 2.1 数据层（schema v3）

| 表 | 变更 | 说明 |
| --- | --- | --- |
| `bookmarks` | `page_index` 改为可空；新增 `position REAL NULL` | PDF 仍存页码；EPUB 存 0–1 位置 |

- `AppDatabase.schemaVersion = 3`，`TableMigration(bookmarks, newColumns: [position])` 重建表。
- 迁移测试补：v2 旧书签升级后页码保留、`position = null`；可写入 EPUB 书签。
- 排版设置存 `app_meta`：`reader.epub.font_level`（0–4）、`reader.epub.line_spacing_level`（0–1），
  由 `ReaderTypographyRepository` 读写，全局生效。
- 书架进度：`ProgressDao.watchAll()` + `LibraryController` 合并文档流与进度流；
  `BookTile` 对 EPUB 显示「作者 · 位置 N%」。

### 2.2 EPUB 包与内容（core/ebook）

- `EpubSession`：打开 EPUB 文件，持有 ZIP 归档；解析 container / OPF，得到
  spine 阅读顺序（仅 XHTML/HTML 项）、manifest 媒体类型；按包内相对路径读文本 / 资源。
- `EpubContentParser`：XHTML → 块模型。
  - 块：标题 h1–h6、段落、列表项、引用、图片、分隔线。
  - 行内：粗体、斜体、下划线、代码（等宽）。
  - 记录每个块的起始字符偏移与锚点（`id`）字符偏移，供目录 fragment 与进度恢复定位。
  - 解析失败抛中文异常，阅读页显示本章失败提示，不崩。

### 2.3 分页引擎

- `EpubTypography`：字号 5 档（14/16/18/20/22）、行距 2 档（1.5/1.8）、
  页边距 24 dp；标题、段距、缩进按字号比例推导。
- `EpubPaginator`：逐块用 `TextPainter` 在内容宽度内测量，按可用高度装页。
  - 段首缩进用两个全角空格；分行在行边界处切分，续页不重复缩进。
  - 图片先读包内字节取原始宽高，按内容宽等比缩放；放不下就整张移到下一页。
  - 每排完一页让出事件循环并通知 UI，单章渐进排版；取消标记用于切章 / 改设置。
- 章节缓存：`Map<spineIndex, ChapterLayout>`，容量 3；字号 / 行距 / 视口变化时整体失效。
- 位置：`position = (spineIndex + 章内字符比例) / spineCount`；恢复时反算出章节与字符偏移，
  再找包含该字符的页。重排只重算当前章，按当前页起始字符落回同一段。

### 2.4 阅读页外壳

- 从现有 `ReaderPage` 抽出 `ReaderShell`：沉浸式、书签入口位置记忆、三态、手势排除、
  面板动画、返回键、添加书签提示。PDF 与 EPUB 共用。
- `ReaderSession` 抽象：加载 / 错误、面板状态、书签与目录、翻页、跳转、进度保存。
  `ReaderController`（PDF）与 `EpubReaderController` 各自实现。
- `ReaderPanelTab` 增加 `typography`；`BookmarkPanel` 在 EPUB 下多一个「排版」页签。
- `TocList` 改为按条目对象跳转，PDF 显示页码，EPUB 不显示页码；当前章按 href 高亮。
- 书签副标题：PDF「第 N 页」，EPUB「位置 N%」。

### 2.5 交互

- 翻页：复用 `PageTurnLayer`；`nextPage` 在章末会懒排版下一章；末章末页提示「已到全书末尾」。
- 翻页时若目标页尚未排完，显示轻量加载占位，排版继续在后台推进。
- 目录跳转：href → spine 索引；fragment → 锚点字符偏移；整章排到目标页后跳转。
- 书签：记录当前页起始字符对应的 `position`；跳转同进度恢复。
- 返回键：面板打开时先关面板。

## 3. 任务清单

### 3.1 数据层

- [x] `tables.dart`：`bookmarks.pageIndex` 可空、新增 `position`
- [x] `app_database.dart`：schemaVersion 3 + 迁移
- [x] `BookmarkRepository`：`add` 支持 `position`、PDF 书签保持原逻辑
- [x] `ProgressDao.watchAll` + `LibraryController` + `BookTile` 百分比
- [x] `ReaderTypographyRepository`
- [x] build_runner 重新生成 drift 代码

### 3.2 核心解析

- [x] `EpubSession`：ZIP、OPF、spine、资源读取
- [x] `EpubContentParser`：块模型、行内样式、锚点
- [x] 单测：spine 顺序、相对路径、标题/列表/引用/粗斜体、锚点、坏章节降级

### 3.3 分页

- [x] `EpubTypography` 与 `EpubPaginator`
- [x] 段首缩进、行边界切分、图片等比、标题/列表/引用样式
- [x] 渐进排版与取消；章节缓存；位置映射
- [x] 单测：装页、跨页切分、图片、字号变化后同段、position 往返

### 3.4 阅读页

- [x] 抽取 `ReaderShell`，PDF 改为复用（行为不变）
- [x] `ReaderSession` + `ReaderController` 适配
- [x] `EpubReaderController`：加载、恢复、翻页、跨章、末尾提示、书签、目录、保存
- [x] `EpubReaderPage`：页面渲染、加载占位、失败提示
- [x] `BookmarkPanel` / `TocList` 适配 EPUB
- [x] 「排版」页签 + 独立组件 `TypographySettingsPanel`
- [x] 字号 / 行距重排保持当前段；横竖屏切换保持位置

### 3.5 验证

- [x] `flutter test`、`flutter analyze --no-pub`
- [x] Windows debug 构建
- [x] 里程碑 1：翻页读通、目录跳转、退出重进回原处
- [x] 里程碑 2：字号重排、横竖屏切换

## 4. 进度记录

| 时间 | 事项 | 结果 |
| --- | --- | --- |
| 2026-11-16 | 建立 TODO 与方案 | 完成 |
| 2026-11-16 | 数据层 v3、EPUB 会话/内容解析、分页引擎、阅读页外壳与排版页签 | 完成 |
| 2026-11-16 | 分页/内容/spine/迁移单测 | 通过 |
| 2026-11-16 | 发现并修复：退出时进度退化为章首（`dispose` 先清缓存后保存） | 已修复并为用例覆盖 |
| 2026-11-16 | 发现并修复：初始化恢复竞态、重排闪回章首、旧跳转覆盖新位置 | 已修复 |
| 2026-11-16 | 全量 `flutter test` | 72 条全过 |
| 2026-11-16 | `flutter analyze --no-pub` | 无 error / warning（22 条既有 deprecation info） |
| 2026-11-16 | `flutter build windows --debug` | 构建通过 |
| 2026-11-16 | 里程碑 1（翻页读通 / 目录跳转 / 退出重进回原处） | 集成用例通过 |
| 2026-11-16 | 里程碑 2（字号重排 / 横竖屏切换保持同段） | 集成用例通过 |
| 2026-11-16 | Android 模拟器手工复核（Pixel 5 API 30） | 通过：导入、翻页、中间不翻、跨章、目录跳转、恢复、字号重排、横竖屏、返回键、末尾提示 |
| 2026-11-16 | 修复面板顶部 1.5px 横向溢出（页签行改为可滚动 + 紧凑按钮） | 已修复并重新安装验证 |
| 2026-11-16 | `flutter run -d android` 排查 | 原因是未启动设备/模拟器；启动后构建、安装、启动均正常 |
