# 模块：扫描本机文件（features/scan）

- 目录：`lib/features/scan/{application,presentation}`
- 所属层：presentation + application
- 状态：M2 第一轮完成（遍历扫描 + 多选导入）/ M1-015 支持 EPUB

## 职责

1. 权限：查询/申请「所有文件访问权限」（Android 11+）或 `READ_EXTERNAL_STORAGE`（Android 10-）。
2. 扫描：后台 isolate 遍历扫描根，只收 PDF / EPUB；PDF 校验 `%PDF-` 文件头，EPUB 校验 ZIP 魔数；
   回传进度、可取消。
3. 展示：文件名、所在目录、大小；标签优先级为 导入失败原因 → 可能损坏 → 已在书架。
4. 导入：多选 → 逐文件走 `DocumentRepository.importFile`（格式校验 / sha256 去重 / 封面 / 入库），结束后汇总提示。
5. 空态：无结果显示「没有找到 PDF 或 EPUB 文件」+ 已扫描数量 +「重新扫描」。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `ScanPage` | 扫描页，路由 `/scan` |
| `ScanController` | 状态：`access` / `scanning` / `visited` / `found` / `results` / `selected` / `importing`；动作：`prepare` / `requestAccess` / `startScan` / `cancelScan` / `toggleSelected` / `selectAll` / `clearSelection` / `importSelected` |
| `ScanImportSummary` | `imported` / `duplicates` / `failures` + 中文 `message` |
| `BookScanService.scan(roots)` | `Stream<ScanEvent>`（进度 / 完成 / 失败） |
| `ScannedBook` | `path` / `name` / `directory` / `sizeBytes` / `format`（`pdf` / `epub`）/ `hasValidHeader`（`looksBroken`） |
| `formatOfFileName(name)` | 扩展名大小写不敏感判定，只接受 PDF / EPUB（其它返回 null） |
| `formatBytes(bytes)` | B / KB / MB / GB |

## 依赖关系

- 依赖：`core/platform: StorageAccess`、`core/ebook: BookFormat / formatOfFileName`、`data/repos: DocumentRepository`、`core/utils: AppLogger`
- 被依赖：`app/router`、`features/library`（导入入口）
- 禁止：在 UI 线程做目录遍历；在扫描页重复实现导入/封面/EPUB 解析逻辑。

## 约束

- 只按 PDF / EPUB 判定：扩展名（大小写不敏感）+ 文件头（PDF `%PDF-`、EPUB `PK\x03\x04`）。
  EPUB 的完整 `mimetype` 校验留给导入，避免扫描时解压大量文件；MIME 不作为门槛。
- 去重三层：扫描内按路径去重（Windows 路径小写）；与书架按 `标题(去扩展名,小写)|文件大小` 标「已在书架」；真正入库仍由 sha256 判定重复。
- 遍历跳过：`windows` / `program files` / `programdata` / `$recycle.bin` / `appdata` / `node_modules` / `.git` / `.dart_tool` / `.gradle` / `.idea` / `.vscode` / `windowsapps` / `pub-cache` / `.trae*`，以及 Android 的 `/android/data`、`/android/obb`。
- 扫描根：Android = 共享存储根 + 外置卷；Windows = 用户 Downloads/Documents/Desktop/OneDrive + D:–Z:（系统盘不全盘扫）。
- 坏文件不崩：打开失败只记录原因并给条目打标，不抛出到页面。

## 验证

- 单测：`test/features/scan/book_scan_service_test.dart`（PDF / EPUB 混合、大小写扩展名、伪装 EPUB 标记损坏、其它格式排除）。
- 模拟器 `Pixel_5_API_30`：12 个 PDF / 409 个 PDF / 空结果 / 未授权权限卡 / 授权后自动重扫 / 多选导入（成功、重复、损坏各 1）。
- Windows：桌面端启动正常；用真实目录跑扫描服务命中 PDF 与 EPUB。
