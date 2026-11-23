# 模块：仓库（data/repos）

- 目录：`lib/data/repos`
- 所属层：data / domain 接口实现
- 状态：M0 建设 / M1-015 支持 EPUB 导入 / M1-016 位置书签、进度订阅与排版设置

## 职责

1. 聚合 DAO + 文件系统 + 格式解析，向上提供用例级 API。
2. 保证事务边界：一次划线（含跨页拆分后的多行）一个事务；导入流程「复制文件 → 解析 → 写库」失败可回滚。
3. 把 `PdfEngine` / EPUB 解析器的输出转换为 domain 模型（归一化坐标、0 基页码或 EPUB 定位）。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `DocumentRepository` | `importFile(path)`、`list()`、`byId(id)`、`delete(id)`、`openHandle(document)` |
| `ProgressRepository` | `load(documentId)`、`save(documentId, pageIndex, position, offsetY, zoom)`：PDF 用 `pageIndex`，EPUB 用 `position`（0–1）；`watchAll()` 供书架百分比订阅 |
| `BookmarkRepository` | `add({documentId, pageIndex, position, posY, label})`、`list(documentId)`、`rename(...)`、`remove(...)`、`clear(documentId)`；PDF 默认标签「第 N 页」，EPUB「位置 N%」 |
| `HighlightRepository` | `add(range, note, color)`、`listByPage(...)`、`updateNote(...)`、`remove(...)` |
| `TocRepository` | `list(documentId)`、`loadOrParse(documentId, readOutline)`（缓存优先，缺失时解析并落库；EPUB 目录在导入时已落库） |
| `ReaderEntryPositionRepository` | `load(isLandscape)` / `save(isLandscape, ratio)`：书签入口**纵向**比例（0..1），竖屏/横屏各一份，存 `app_meta`（`reader.entry_y.portrait` / `reader.entry_y.landscape`）；读取时清理贴顶时期的旧键 `reader.entry_x.*` |
| `ReaderTypographyRepository` | `load()` / `save(typography)`：字号 / 行距档位，存 `app_meta`（`reader.epub.font_level` / `reader.epub.line_spacing_level`），非法值回退默认 |
| `ImportSuccess` / `ImportDuplicate` / `ImportInvalid` | 导入结果：成功行 / 重复行 / 中文失败原因 |

## 依赖关系

- 依赖：`data/db`、`core/pdf`、`core/ebook`（EPUB 校验与解析）、`core/storage`、`core/geometry`、`core/utils/hashing`
- 被依赖：`features/*/application`（通过 riverpod provider 注入）
- 禁止：仓库不含 UI 文案决策逻辑（只返回结构化结果，文案在 presentation）；不把 EPUB 锚点写进页码字段。

## 约束

- 去重以 `sha256` 唯一约束兜底，并发导入同一文件不得产生两条记录；PDF 与 EPUB 共用同一哈希去重。
- PDF 导入流程保持原样：扩展名 → `%PDF-` → 引擎页数/文字层 → 复制到 `pdfs/` → 首页封面。
- EPUB 导入：ZIP + mimetype 校验 → 解析元数据/封面/目录 → 复制到 `epubs/{uuid}.epub` →
  封面写 `covers/{uuid}.{ext}` → `documents(format='epub', page_count=null)` →
  目录整体写 `toc_entries`（`href` + `fragment`，`page_index=null`）。
- 封面或目录失败只降级，不阻断导入；校验失败返回中文 `ImportInvalid`，不向 UI 抛异常。
- 删除顺序：先删 DB（级联）再删文件，文件失败仅记日志。
- 书签入口位置按 `app_meta` 的 `insertOnConflictUpdate` 覆盖保存；值先 `clamp(0,1)` 再存 6 位小数。旧键（`reader.entry_x.*`）只在读取时删除，不参与迁移计算，避免升级后位置错乱。
- EPUB 书签只写 `position`（0–1）并把 `page_index` 置空；PDF 书签只写 `page_index`。两者共用同一张表。
- 排版设置写入前先校验档位范围，读取到非法值回退默认，不让坏数据影响分页。

## 验证

- 单测：`test/data/repos/epub_import_test.dart`（导入成功、封面落盘、目录 href/fragment、伪装 epub 拒收、重复导入）。
- 单测：导入去重、损坏/加密拒绝、删除级联与文件残留断言（既有 PDF 用例保持通过）。
- 迁移：`test/data/db/migration_test.dart`（v1 → v3，EPUB 位置书签与旧 PDF 页码书签并存）。
- 阅读页集成：`test/features/reader/epub_reader_controller_test.dart`（进度 / 书签 / 排版设置经仓库走通）。
