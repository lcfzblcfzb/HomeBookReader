# 模块：数据库（data/db）

- 目录：`lib/data/db`
- 所属层：data
- 状态：M0 建设 / M1-015 schema v2（EPUB 字段）/ M1-016 schema v3（位置书签）

## 职责

1. 表定义：`documents`、`reading_progress`、`bookmarks`、`highlights`、`toc_entries`、`app_meta`。
2. 外键与索引：`PRAGMA foreign_keys = ON`，子表 `ON DELETE CASCADE`。
3. 迁移：schema 版本号 + 升级脚本 + 迁移测试。
4. DAO：单表 CRUD 与聚合查询，不含业务规则。

## 表结构要点（v3）

| 表 | 与电子书格式相关的字段 |
| --- | --- |
| `documents` | `format TEXT NOT NULL DEFAULT 'pdf'`（`pdf` / `epub`）；`page_count INTEGER NULL`（EPUB 为 null）；`author` 可空（EPUB 取 OPF `dc:creator`） |
| `reading_progress` | `page_index INTEGER NULL`（PDF）；`position REAL NULL`（EPUB，0–1） |
| `bookmarks` | `page_index INTEGER NULL`（PDF）；`position REAL NULL`（EPUB，0–1）；`pos_y REAL NOT NULL` 保留 |
| `toc_entries` | `page_index INTEGER NULL`（PDF）；`href TEXT NULL` + `fragment TEXT NULL`（EPUB，相对 OPF 目录的路径 + 片段） |

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `AppDatabase` | 打开/关闭数据库，暴露各 DAO；`schemaVersion = 3` + `MigrationStrategy` |
| `DocumentsDao` | insertDocument / bySha256 / listAll / watchAll / byId / touchOpened / deleteById |
| `ProgressDao` | byDocument / watchAll / upsert（按 documentId） |
| `BookmarksDao` | listByDocument（PDF 按 page_index，EPUB 按 position）/ insert / updateLabel / delete / deleteAll |
| `HighlightsDao` | listByDocument / insert / updateNote / delete |
| `TocDao` | listByDocument / isParsed / replaceAll（整体替换 + `app_meta` 标记已解析） |
| `AppMetaDao` | get / put |

## 依赖关系

- 依赖：drift + drift_flutter、`core/storage`（数据库文件位置）
- 被依赖：`data/repos` 唯一
- 禁止：`features/*` 直接 import DAO；DAO 不返回值对象以外的 UI 类型。

## 约束

- 时间字段统一 epoch 毫秒 INTEGER。
- `page_index` 只在 PDF 语义下使用；EPUB 的目录锚点必须写 `href` / `fragment`，禁止塞进页码字段。
- EPUB 阅读进度与书签只写 `position`（0–1），PDF 只写 `page_index`；`pos_y` 单页模式恒为 0。
- 破坏性变更不得直接删列；需附导出/导入方案。
- 任何表结构变更必须同时提交迁移测试。
- v1 → v2 用 `TableMigration` 重建表，旧 PDF 数据原样保留；新列 `format` 默认 `'pdf'`。
- v2 → v3 用 `TableMigration(bookmarks, newColumns: [bookmarks.position])` 重建表；
  `page_index` 改可空，旧 PDF 书签数据保留。

## 验证

- 迁移测试：`test/data/db/migration_test.dart`（v1 旧库直接升级到 v3：文档/进度/目录保留，
  EPUB 字段可写，EPUB 位置书签 `page_index = null` + `position`，旧 PDF 页码书签仍可写）。
- 单测：建表 + 级联删除断言（删 `documents` 后四张子表计数为 0）。
