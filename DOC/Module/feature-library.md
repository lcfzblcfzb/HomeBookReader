# 模块：书架（features/library）

- 目录：`lib/features/library/{presentation,application,widgets}`
- 所属层：presentation + application
- 状态：M0 骨架 / M1 实现 / M1-015 EPUB 与 PDF 混排 / M1-016 EPUB 进入分页阅读页并显示进度百分比

## 职责

1. 书架模式：PDF 与 EPUB 混排，展示封面、书名、作者与进度——PDF 显示页数，EPUB 显示「位置 %」；点按进入阅读模式（PDF / EPUB 分别走对应阅读页）。
2. 导入：「+」（及空态按钮）弹出底部菜单，两个入口——「选择 PDF / EPUB 文件」走系统文件选择器（支持多选，逐文件展示进度与失败原因）；「扫描本机文件」跳 `/scan`（见 [feature-scan](./feature-scan.md)）。
3. 空态引导：无书时提示「导入本地 PDF / EPUB 开始阅读」。
4. 设置入口：本轮只放入口与占位页。
5. 删除：二次确认，调用仓库级联清理。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `LibraryPage` | 书架页（应用首页） |
| `LibraryController` | `ChangeNotifier`：`items` / `positionOf(documentId)` / `pickAndImport()` / `recoverLostImport()` / `delete(id)`；订阅文档流与进度流 |
| `BookTile` | 单个文档条目（封面懒加载；按 `document.format` 切换副标题与占位图标；EPUB 显示位置百分比） |
| `ImportReport` | `imported` / `duplicates` / `failures` / `cancelled` |

## 依赖关系

- 依赖：`data/repos: DocumentRepository`、`core/ebook: BookFormat`、`core/storage`、`app/theme`、`app/router`
- 被依赖：`app/router`（作为首页路由）、`features/scan`（由本页入口跳转）
- 禁止：直接调用 `pdfrx`；直接解析 EPUB；在 UI 层判断文件格式细节。

## 约束

- 封面缺失或解码失败时用占位块，不阻塞列表渲染；100 本首屏 ≤ 1s。
- 导入失败给出中文原因（损坏 / 加密 / 非 PDF 或 EPUB / 已在书架）。
- EPUB 条目点击进入 `EpubReaderPage`（分页阅读），不再弹「阅读页待做」；PDF 进入 `ReaderPage`。
- 进度显示：PDF 取 `reading_progress.page_index`，EPUB 取 `position`（0–1）四舍五入为百分比；
  阅读页返回或翻页后由进度流自动刷新。
- 不实现拖拽导入、不实现重新关联 UI（大纲 M1 范围）。

## 验证

- 组件测试：`test/features/library/book_tile_test.dart`（EPUB 书名/作者/位置/占位图标；PDF 页数与无文字层文案）。
- 仓库测试：`test/data/repos/epub_import_test.dart`（导入后封面落盘、书架行字段正确）。
- EPUB 阅读集成：`test/features/reader/epub_reader_controller_test.dart`（进度落库后书架可读百分比）。
- 手工冒烟：Windows 导入 PDF + EPUB 后混排显示；重启保留。
