# M2-2 扫描本机 PDF 导入 TODO

> 依据：[开发大纲 §6 M2](../开发大纲.md)（导入链路：本机 PDF 扫描）
> 状态：已完成（模拟器验证；Windows 扫描逻辑用真实目录验证）
> 范围：扫描、筛选、选择、批量导入；不做目录树浏览

## 1. 权限方案（已定）

| 系统版本 | 方案 | 用户看到什么 | 代价 |
| --- | --- | --- | --- |
| Android 11+（API 30+） | `MANAGE_EXTERNAL_STORAGE` | 系统「All files access / 所有文件访问权限」设置页，一个「Allow access to manage all files」开关，打开后返回 | 不能上架 Google Play（个人自用可接受）；权限声明较宽 |
| Android 7–10（API 24–29） | `READ_EXTERNAL_STORAGE` 运行时权限 | 「允许访问设备上的照片、媒体内容和文件？」弹窗 | Android 10 分区存储下，他应用写入的共享目录文件仍可读 |
| Windows | 无需权限 | 无 | 全盘遍历较慢，需跳过系统/缓存目录 |

本项目 targetSdk 36、minSdk 24：取到「本机所有 PDF」的最少权限就是上表两条。
不采用 MediaStore（`MediaStore.Files` 在不同厂商 ROM 上覆盖不全、返回的是 content Uri 而非真实路径，导入还要多一层拷贝）；SAF 目录授权（`ACTION_OPEN_DOCUMENT_TREE`）作为后续可选项，不作为默认。

模拟器（API 30）实测：跳转到系统设置页后，用户看到的是「All files access → HomePdfReader → Allow access to manage all files」单开关页面，页面上带系统提示「Allow this app to read, modify and delete all files on this device or any connected storage volumes」。

## 2. 任务清单

- [x] Android：Manifest 权限 + MethodChannel（状态查询 / 去授权 / 存储根目录）
- [x] 扫描：后台 isolate 遍历，进度回调、可取消
- [x] PDF 判定：扩展名大小写不敏感 + 文件头 `%PDF-`；无法判定标「可能损坏」
- [x] 去重：路径去重；与书架按名称+大小标记「已在书架」，导入仍走 sha256 去重
- [x] 列表：文件名、目录、大小、标记；单选/多选
- [x] 导入：复用 `DocumentRepository.importFile`（校验/去重/封面/入库）
- [x] 空态、大量文件、扫描中状态
- [x] Windows 分支持
- [x] 单测（PDF 判定、路径去重）+ 手测（模拟器/Windows）

## 3. 进度记录

| 时间 | 事项 | 结果 |
| --- | --- | --- |
| 2026-11-14 | 权限方案确定 | 见上表；模拟器截图确认系统设置页形态 |
| 2026-11-14 | Android 权限通道 | `MainActivity` 新增 `homepdfreader/storage_access`（status / request / root），API≥30 走 `Environment.isExternalStorageManager()` + 设置页跳转 |
| 2026-11-14 | 扫描服务 | `PdfScanService`：isolate 遍历，150ms 一次进度，支持取消；跳过系统/缓存目录（windows、program files、appdata、node_modules、.git、android/data、android/obb 等）；路径去重（Windows 按小写） |
| 2026-11-14 | 扫描页 | `/scan` 路由；权限卡 / 扫描中（已扫描 N、发现 M、取消）/ 空态 / 结果列表（文件名为标题，目录+大小+标签为副标题） |
| 2026-11-14 | 导入 | 多选 → 逐文件 `importFile`；结束后 SnackBar 汇总「成功 N 本，M 本已在书架，K 个失败」 |
| 2026-11-14 | 模拟器验证 | 12 个 PDF（含大写扩展名 `Sample_Upper.PDF`）、`notes.txt` 被排除；坏文件导入失败标「无法导入」；重复内容（同 sha256）判为已在书架 |
| 2026-11-14 | 大列表验证 | 临时生成 400 份 PDF → 共 409 条，扫描中界面可交互（进度 354/283），列表懒构建滚动流畅 |
| 2026-11-14 | 空结果验证 | 把 PDF 移出扫描根后重扫，显示「没有找到 PDF 文件 / 已扫描 71 个文件」+「重新扫描」 |
| 2026-11-14 | Windows | 桌面端可启动；用真实目录 `test_assets` 跑扫描服务，扫出 6 个 PDF（名称/目录/大小正确），非 PDF 不入列表 |

## 4. 相关文档

- 本轮摘要：[2026-11-14-M2-002-扫描本机PDF](../Guide/2026-11-14-M2-002-扫描本机PDF.md)
- 模块：[feature-scan](../Module/feature-scan.md)
