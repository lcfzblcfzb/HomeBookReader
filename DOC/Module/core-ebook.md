# 模块：电子书格式（core/ebook）

- 目录：`lib/core/ebook`
- 所属层：core
- 状态：M1-015 导入解析（EPUB2 / EPUB3 校验、元数据、封面、目录）；
  M1-016 阅读支持（会话、正文块模型、排版参数）

## 职责

1. 统一格式判定：`BookFormat`（`pdf` / `epub`）与 `formatOfFileName(name)`，供导入、扫描、书架共用。
2. EPUB 容器校验：ZIP 魔数 `PK\x03\x04` + `mimetype` 条目严格等于 `application/epub+zip`；
   再校验 `META-INF/container.xml` 与 OPF 存在。任何失败抛 `EpubInvalidException`（中文原因）。
3. 元数据：`dc:title`、`dc:creator`；标题缺失时返回空串，由仓库回退到文件名。
4. 封面：按优先级取 OPF 声明——
   1) EPUB3 manifest `properties` 含 `cover-image`；
   2) EPUB2 `<meta name="cover" content="id">` 指向的 manifest 项；
   3) `id` / `href` 含 `cover` 的图片兜底。
   取不到、文件缺失或为 SVG 时返回 null（书架用占位，不报错）。
5. 目录：先试 EPUB3 `nav`（`properties` 含 `nav` 的 XHTML，取 `nav[epub:type=toc]` 的嵌套 `ol/li/a`），
   没有再试 EPUB2 NCX（`spine[toc]` 指向的 `navPoint`）。两条都失败返回空列表，不阻断导入。
6. 目录定位：`href` 统一为**相对 OPF 目录、已 URL 解码**的路径，`fragment` 为 `#` 之后的片段；
   不使用页码字段。
7. 阅读会话（`EpubSession`）：复用校验，解析 container → OPF → manifest → spine；
   spine 只收 XHTML/HTML，缺 spine 时按 manifest 顺序回退并跳过 `nav` 文档。
   `spineIndexForHref` 同时接受 OPF 相对路径与包内完整路径。
8. 正文解析（`EpubContentParser`）：XHTML → 标题 1–6 / 段落 / 列表项 / 引用 / 图片 / 分隔线，
   行内粗体、斜体、下划线、等宽；记录块起始字符与 `id` / `name` 锚点。
9. 排版参数（`EpubTypography`）：字号 5 档、行距 2 档、页边距默认值、标题倍率；
   只放纯数值，供分页引擎与设置面板共用。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `BookFormat` | `pdf` / `epub`；数据库存枚举名（`format.name`） |
| `formatOfFileName(name)` | 扩展名大小写不敏感判定，其它格式返回 null |
| `EpubParser.validate(bytes)` | 校验 ZIP + mimetype，返回 `Archive`（失败抛异常） |
| `EpubParser.parse(bytes)` | 校验并解析为 `EpubBook` |
| `EpubBook` | `title` / `author` / `coverBytes` / `coverExtension` / `toc` |
| `EpubTocEntry` | `title` / `level`（1 基）/ `href` / `fragment` / `parentIndex` |
| `EpubSession` | `open(file)` / `openBytes`、`spine`、`readChapter(i)`、`readResource(href)`、`resolveInChapter(chapterHref, src)`、`spineIndexForHref(href)` |
| `EpubContentParser.parse(xhtml, chapterHref:)` | 输出 `EpubChapterContent`（blocks / anchors / charCount） |
| `EpubBlock` / `EpubTextRun` | 块（kind / startChar / 列表信息 / 图片 href）与行内样式 run |
| `EpubTypography` | `fontLevel`、`lineSpacingLevel`、`fontSize`、`lineSpacing`、页边距、`headingScale` |
| `EpubInvalidException` / `EpubContentException` | `reason` 为可直接展示的中文原因 |

## 依赖关系

- 依赖：`archive`（ZIP 解压）、`xml`（OPF / NCX / XHTML）、`path`（包内相对路径）
- 被依赖：`data/repos: DocumentRepository`、`features/scan: BookScanService`、
  `features/reader`（`EpubSession` / `EpubContentParser` / `EpubTypography`）
- 禁止：依赖 Flutter UI 或 `pdfrx`；把 EPUB 的锚点写进页码字段。

## 约束

- `mimetype` 判定是导入的硬门槛，不只看扩展名；损坏或伪装的 epub 必须拒收并给中文原因。
- 包内路径统一按 POSIX `/` 归一化，查找时大小写不敏感；ZIP 条目名允许 `./` 前缀。
- XHTML / OPF 解析使用 HTML5 实体映射，容忍 `&nbsp;` 等常见实体。
- 目录解析失败只降级为空目录；封面失败只降级为占位，二者都不能让导入失败。
- 不校验 OPF 的 EPUB 版本号，EPUB2 / EPUB3 结构均按实际元素识别。
- `EpubSession` 只解析包结构与 spine，不解析正文；正文由 `EpubContentParser` 按章按需解析。
- 块 `startChar` 与锚点偏移都基于本章纯文本，不含排版用的缩进 / 项目符号。
- `EpubTypography` 为不可变值对象，`const` 构造不放下标断言。

## 验证

- `test/core/ebook/epub_parser_test.dart`：EPUB3 nav（含嵌套与片段）、EPUB2 ncx、无封面、
  非 ZIP、缺 mimetype、mimetype 错误、缺 container.xml。
- `test/core/ebook/epub_session_test.dart`：spine 顺序、两种 href 写法、资源读取、空正文拒绝。
- `test/core/ebook/epub_content_test.dart`：标题/段落/粗斜体/列表层级/引用/图片/锚点、坏 XHTML。
- `test/core/ebook/epub_paginator_test.dart`：长段落切页、续页无缩进、图片等比。
- `test/data/repos/epub_import_test.dart`：真实导入链路写库、封面落盘、目录 href/fragment。
