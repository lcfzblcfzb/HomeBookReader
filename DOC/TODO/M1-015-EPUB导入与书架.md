# M1-015 EPUB 支持第一步：导入与书架 TODO

> 依据：[开发大纲](../开发大纲.md) M1 书架与导入
> 状态：代码与自动化验证完成（实机导入真实 EPUB 待补）
> 范围：只做 EPUB2 / EPUB3 的**导入、校验、封面、目录落库、书架混排、扫描识别**；阅读页留到下一步。

## 1. 背景与目标

书架目前只认 PDF，`documents.page_count` 非空、目录只存页码，无法表达 EPUB 无页概念与
`href + 片段` 的定位方式。本步先把 EPUB 纳入数据与导入链路，保证：

- 导入识别不只看扩展名：ZIP 容器 + `mimetype` 条目严格等于 `application/epub+zip`；
  损坏或伪装的 epub 拒收并给中文提示，任何异常都不能让流程崩掉。
- 书架 EPUB 与 PDF 混排，显示封面、书名、作者；封面取 OPF 声明的 cover 图，缺失时占位。
- 进度：PDF 仍是页码；EPUB 用 `position`（0–1 比例）表示「位置」，不硬凑页码。
- 目录：EPUB3 `nav.xhtml` 与 EPUB2 `ncx` 两条路径都解析，落进现有 `toc_entries`；
  定位字段为 `href + fragment`，页码字段留空。
- 扫描本机文件同时识别 EPUB，其它格式继续排除；去重、已在书架标记、批量导入行为不变。
- 数据层按现有 drift 迁移机制升到 v2（新增格式、可空页数、EPUB 定位字段），老数据平滑升级，
  PDF 既有行为零退化。
- 点开 EPUB 给出明确的「阅读页待做」提示，不崩、不空白。

## 2. 方案

### 2.1 数据迁移（schema v1 → v2）

| 表 | 变更 | 说明 |
| --- | --- | --- |
| `documents` | 新增 `format TEXT NOT NULL DEFAULT 'pdf'`；`page_count` 改为可空 | 老数据自动填 `pdf`，页数原值保留 |
| `reading_progress` | `page_index` 改为可空；新增 `position REAL NULL`（0–1） | PDF 用 `page_index`，EPUB 用 `position` |
| `toc_entries` | `page_index` 改为可空；新增 `href TEXT NULL`、`fragment TEXT NULL` | PDF 用页码；EPUB 用 `href + fragment` |

- `AppDatabase.schemaVersion = 2`，`MigrationStrategy.onUpgrade` 用 `TableMigration` 重建表，
  复制旧列、为新列补默认值；`beforeOpen` 打开外键。
- 迁移测试：用 v1 建表 SQL 造一份旧库（含 PDF 文档、进度、目录），打开 v2 后断言数据保留、
  新字段默认值正确、可写入 EPUB 记录。

### 2.2 EPUB 校验与解析（新增 `lib/core/ebook/`）

- `BookFormat`：`pdf` / `epub`，统一扩展名判定 `formatOfFileName`。
- `EpubParser.validate(bytes)`：
  1. ZIP 魔数 `PK\x03\x04`；
  2. 能解压出 `mimetype` 条目；
  3. 内容（去空白）严格等于 `application/epub+zip`；
  4. `META-INF/container.xml` 可解析并指向存在的 OPF。
  任一失败抛 `EpubInvalidException`（带中文原因），由仓库转成 `ImportInvalid`。
- `EpubParser.parse(bytes)`：
  - OPF：`title` / `creator`（`dc:title`、`dc:creator`，兼容 `opf:` 前缀）。
  - 封面：EPUB3 `properties="cover-image"` → EPUB2 `<meta name="cover" content="id">` →
    manifest 中 `id/href` 含 cover 的图片兜底；取不到返回 null（书架占位）。
  - 目录：
    - EPUB3：manifest 中 `properties` 含 `nav` 的 XHTML，取 `nav[epub:type="toc"]` 的嵌套 `ol/li/a`；
    - EPUB2：`spine[toc]` 指向的 NCX，解析嵌套 `navPoint`；
    - 两条路径都失败则空目录（不阻断导入）。
  - 每条目录包含 `title`、`level`、`href`（相对 OPF 目录、已 URL 解码）、`fragment`（`#` 之后，可空）。

### 2.3 导入流程（`DocumentRepository.importFile`）

- 扩展名分流：`.pdf` 走原逻辑（完全不改）；`.epub` 走新分支；其它格式提示「仅支持 PDF 与 EPUB 文件」。
- EPUB：校验 → sha256 去重（与 PDF 共用）→ 解析 → 复制到 `epubs/{uuid}.epub` →
  写封面到 `covers/{uuid}.{jpg|png|...}`（失败不阻断）→ 入库（`format='epub'`、`page_count=null`、
  `has_text_layer=true`）→ 目录整体写入 `toc_entries` 并标记已解析。
- 失败一律返回中文 `ImportInvalid`，不向 UI 抛异常。

### 2.4 书架与扫描

- `BookTile`：PDF 副标题仍是「N 页 · 无文字层」；EPUB 显示「作者 · 位置 0%」（无作者用「未知作者」），
  封面占位图标区分 PDF / EPUB。
- 书架导入入口：文件选择器允许 `pdf` + `epub`；文案改为「选择 PDF / EPUB」；空态同改。
- 点开 EPUB：弹窗「阅读页待做」，不跳阅读页；`ReaderController` 也做兜底，深链进入同样给提示。
- 扫描：`ScannedBook` 增加 `format`；EPUB 用 ZIP 魔数快速判损坏（完整 mimetype 校验留给导入）；
  其它扩展名仍排除；标签、去重、批量导入逻辑不变。

## 3. 任务清单

### 3.1 数据层

- [x] `tables.dart`：`documents.format`、可空 `pageCount`；`reading_progress.position`、可空 `pageIndex`；`toc_entries.href/fragment`、可空 `pageIndex`
- [x] `app_database.dart`：schemaVersion 2 + `MigrationStrategy`（含外键开启）
- [x] `build_runner` 重新生成 drift 代码
- [x] 迁移单测：v1 旧库升级后数据保留、默认值正确、EPUB 字段可写

### 3.2 EPUB 核心

- [x] `core/ebook/book_format.dart`：格式枚举与扩展名判定
- [x] `core/ebook/epub_models.dart`：包信息、封面、目录条目、异常
- [x] `core/ebook/epub_parser.dart`：ZIP + mimetype 校验、OPF、封面、nav + ncx 目录
- [x] 单测：EPUB3 nav、EPUB2 ncx、无封面、错误 mimetype、非 ZIP、目录片段

### 3.3 导入与书架

- [x] `AppPaths`：新增 `epubs/` 目录
- [x] `DocumentRepository`：EPUB 导入、封面写入、目录落库；PDF 分支保持原样
- [x] `LibraryController`：允许 pdf/epub、文案与日志适配可空页数
- [x] `BookTile`：作者 + 位置副标题、EPUB 占位图标
- [x] `LibraryPage`：导入文案、EPUB 点击提示
- [x] `ReaderController`：EPUB 兜底提示

### 3.4 扫描

- [x] `BookScanService`：识别 EPUB（ZIP 魔数）、返回 `BookFormat`
- [x] `ScanController` / `ScanPage`：文案与标签适配
- [x] 扫描单测更新：PDF + EPUB 混合、伪装 EPUB 标记损坏、其它格式排除

### 3.5 验证

- [x] `flutter test` / `flutter analyze --no-pub`
- [ ] 实机导入一本真实 EPUB：书架可见封面与书名（结构化样本已在自动化测试中验证，实机待补）
- [x] 再验目录落库（nav 与 ncx 样本各一）、伪装 epub 拒收、扫描混合识别、PDF 回归

## 4. 进度记录

| 时间 | 事项 | 结果 |
| --- | --- | --- |
| 2026-11-16 | 建立 TODO 与方案 | 完成 |
| 2026-11-16 | schema v2 迁移 + drift 代码生成 | 完成，迁移测试通过 |
| 2026-11-16 | EPUB 校验/解析 + 导入 + 书架混排 | 完成，导入测试通过（里程碑） |
| 2026-11-16 | 目录 nav/ncx 落库 + 扫描识别 + 阅读页提示 | 完成 |
| 2026-11-16 | 全量测试 | 63 条通过，analyze 无 error，Windows debug 构建通过 |
