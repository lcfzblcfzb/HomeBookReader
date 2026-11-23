# 模块：本地存储路径（core/storage）

- 目录：`lib/core/storage`
- 所属层：core
- 状态：M0 建设 / M1-015 新增 `epubs/`

## 职责

1. 解析应用私有目录（`getApplicationSupportDirectory`），作为唯一根路径。
2. 相对路径 ↔ 绝对路径拼接：`pdfs/{documentId}.pdf`、`epubs/{documentId}.epub`、`covers/{documentId}.{ext}`。
3. 目录初始化、孤儿文件清理、缓存体积统计。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `AppPaths.root` | 私有根目录绝对路径（启动期 `init()` 后可用） |
| `AppPaths.init()` | 解析并创建 `pdfs/`、`epubs/`、`covers/` |
| `AppPaths.pdfsDir` / `epubsDir` / `coversDir` | 各资源目录 |
| `AppPaths.resolve(relPath)` | 相对路径 → 绝对 `File` |
| `AppPaths.toRelative(absolute)` | 绝对路径 → 相对路径（入库用） |
| `AppPaths.listPdfFiles()` | 枚举现有 PDF 文件（孤儿清理用） |

## 依赖关系

- 依赖：`path_provider`、`path`
- 被依赖：`data/repos`、`features/library`（导入复制、删除清理）
- 禁止：任何模块自行拼绝对路径入库；DB 只存相对路径（R7）。

## 约束

- Windows / Android / iOS 三端路径分隔符差异由 `package:path` 统一处理。
- 根路径不缓存到数据库，每次启动重建。
- EPUB 与 PDF 分目录存放（`pdfs/` / `epubs/`），封面共用 `covers/`，扩展名按图片实际类型。
- 文件删除失败只记日志，不阻断主流程；下次启动做孤儿清理。

## 与共享存储的关系

本模块只管应用私有目录。扫描本机文件需要共享存储读权限，通道在 `lib/core/platform/storage_access.dart`（`StorageAccess.status()` / `request()` / `androidRoot()`），方案与代价见 [feature-scan](./feature-scan.md)。

## 验证

- 单测：`resolve` / `toRelative` 往返一致；启动初始化可重复调用且幂等（`pdfs/`、`epubs/`、`covers/` 均创建）。
