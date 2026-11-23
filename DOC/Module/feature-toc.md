# 模块：目录（features/toc）

- 目录：`lib/features/toc/{presentation,application,widgets}`
- 所属层：presentation + application
- 状态：M3 第一轮（目录列表 + 跳转）已完成；M1-015 支持 EPUB 目录落库；M1-016 EPUB 目录可点击跳转与当前章高亮；章节预览待做

## 职责

1. PDF：outline 解析结果缓存到 `toc_entries`，二次打开直接读库；EPUB：`nav.xhtml` / `ncx` 在导入时解析并落库，阅读页直接读缓存。
2. 扁平化后按文档顺序展示（层级缩进、长标题截断），点击跳转：
   PDF 用 0 基页码；EPUB 用 `href + fragment`，由阅读页换算成章内字符偏移。
3. 当前条目高亮：PDF 按当前页反查所属目录项（文档顺序中最后一个目标页 ≤ 当前页的条目）；
   EPUB 按当前 spine 文件路径匹配 `href`（同一章内多个 fragment 不细分）。
4. 章节快速预览：目标页缩略图 + 页码范围，确认后跳转（未做）。
5. 无 outline 降级：扫描件提示「该文档是扫描件，没有可用的目录。」，可选中无目录的文档提示「该文档未提供目录。」。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `TocList` | 目录列表（挂在书签面板的「目录」页签内），参数：`entries`、`currentHref`、`isCurrentEntry(entry)`、`locationLabel(entry)`、`onJumpEntry(entry)` |
| `TocRepository` | `list(documentId)`、`loadOrParse(documentId, readOutline)` |
| `flattenOutline` | outline 树 → 扁平列表（`level`、`parentIndex`、`sortOrder`） |
| `currentSectionIndex` | PDF 当前页所属条目下标 |

## 依赖关系

- 依赖：`data/repos: TocRepository`、`core/pdf`（PDF outline、扁平化）、`core/ebook`（EPUB 解析）、`features/reader`（跳转与当前位置回调）
- 被依赖：`features/bookmarks`（面板页签容器）
- 禁止：目录面板每次打开都重新解析 outline；把 EPUB 的 `href` / `fragment` 转成假页码。

## 约束

- PDF 跳转使用文档内部 0 基页码；界面展示页码时才 +1。
- EPUB 条目 `page_index` 为 null，可点击；跳转目标为 `href` + 可选 `fragment`。
  `href` 是相对 OPF 的路径，阅读页需同时兼容包内完整路径。
- PDF 目标页为 -1 或 null 的条目只展示、不可点；EPUB 缺 `href` 的条目同样只展示。
- EPUB 条目副标题显示「位置 N%」；没有位置信息时（目录未落到已排版章）留空，不显示假页码。
- 2000 条目录滚动无卡顿：需扁平化 + 懒构建。
- outline 解析在后台进行，不阻塞首屏；解析失败只影响目录页签。

## 验证

- 单测：`test/core/pdf/outline_flatten_test.dart`（层级、父子下标、空目录、当前章节命中）。
- EPUB：`test/core/ebook/epub_parser_test.dart`（nav / ncx 层级与片段）、`test/data/repos/epub_import_test.dart`（目录写入 `href + fragment`，`page_index = null`）。
- EPUB 阅读页：`test/features/reader/epub_reader_controller_test.dart` 覆盖「第三节」带 fragment 的跳转与当前章匹配。
- 集成：`integration_test/m1_smoke_test.dart` 断言目录非空、页码在文档范围内。
- 模拟器：目录列出 4 条、当前章高亮、点击跳页、扫描件空态、二次打开走缓存（无解析日志）。
- EPUB 目录真机点击与 fragment 落点待复核。
