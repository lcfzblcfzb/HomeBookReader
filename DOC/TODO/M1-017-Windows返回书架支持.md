# M1-017 Windows 返回书架支持 TODO

> 依据：[开发大纲](../开发大纲.md) §2.4 退出方式（返回键回书架）+ M6 三端适配中
> 「Windows 快捷键（Esc 关闭弹层）」提前落实
> 状态：已完成（组件测试 + Windows 真机集成冒烟通过）
> 范围：阅读页返回书架在三端可用——安卓系统返回键（已有）之外，Windows 提供
> Esc 按键路径；书签面板头部增加「书架」按钮作为显式入口。
> 明确不做：其他 Windows 快捷键（翻页 / 缩放 / 打开）、鼠标侧键、多窗口。

## 1. 背景

- 阅读页是沉浸式全屏（无常驻工具栏），安卓用系统返回键回书架，Windows 上目前
  没有任何返回书架的途径（只有错误态里有「返回书架」按钮）。
- 书签面板只有「关闭」按钮，只能关面板不能回书架；Windows 用户需要显式入口。

## 2. 目标

1. Windows：阅读页按 Esc——面板打开时先关面板，面板关闭时返回书架，
   与安卓返回键行为完全一致。
2. 书签面板头部增加「书架」按钮：任意页签下可见，点击直接返回书架。
3. PDF 与 EPUB 共用同一行为（都走 `ReaderShell`）。
4. 不影响安卓：返回键行为不变；「书架」按钮为三端通用入口。

## 3. 方案

- `ReaderShell`：`PopScope` 内包一层 `CallbackShortcuts`（Esc 绑定）+
  `Focus(autofocus: true)`。Esc 分支：`bookmarksVisible` → `closeBookmarks()`；
  否则 `context.go('/')`。键盘事件沿焦点链冒泡，正文若有焦点节点也兜得住。
- `BookmarkPanel`：新增必填回调 `onGoToBookshelf`；头部在「关闭」按钮前放
  `TextButton.icon`（`Icons.library_books` + 文字「书架」，紧凑密度，与
  「当前位置/当前页」按钮同规格）。页签行已是 `Expanded + 横向滚动`，不会挤溢出。
- `ReaderShell` 传入 `onGoToBookshelf: () => context.go('/')`。
- 返回书架统一 `context.go('/')`，`ReaderShell.dispose` 的进度落库与沉浸式恢复
  照常执行。

## 4. 任务清单

### 4.1 界面

- [x] `ReaderShell`：Esc 快捷键 + 焦点节点，先关面板再回书架
- [x] `BookmarkPanel`：`onGoToBookshelf` 回调 + 头部「书架」按钮
- [x] `ReaderShell` 接线 `onGoToBookshelf`

### 4.2 验证

- [x] 组件测试：面板打开按 Esc 只关面板且不离开阅读页
- [x] 组件测试：面板关闭按 Esc 返回书架路由
- [x] 组件测试：面板「书架」按钮点击返回书架路由
- [x] `flutter test` 全量通过（75 条）
- [x] `flutter analyze --no-pub` 无 error / warning（24 条既有 material deprecation info）
- [x] Windows 集成冒烟（`-d windows` 真实窗口真实按键）：Esc 关面板 → Esc 回书架
      → 面板按钮回书架；另通过 `flutter build windows --debug`

## 5. 环境限制记录

- flutter test 框架拉起的 App 进程被本机环境拒绝写 `AppData`（Roaming/Local）与
  `Temp`，仅允许写工程目录；导入链路（复制文件到私有目录）无法在集成测试内完成。
  既有 `integration_test/m1_smoke_test.dart` 在同一环境下同样失败（PDF 解析正常，
  复制阶段 `errno = 5`），属环境限制而非代码回归；普通 `dart` 进程与用户终端直接
  运行的应用不受影响（私有目录当天仍有正常写入）。
- 因此本条冒烟改用假会话驱动真外壳、真路由、真键盘事件（`m1_reader_return_smoke_test.dart`），
  覆盖「真实 Windows 窗口 + 真实按键路径」这一关键差异点；导入 → 阅读 → Esc 的
  完整链路留待用户终端手工复核。

## 6. 进度记录

| 时间 | 事项 | 结果 |
| --- | --- | --- |
| 2026-11-16 | 建立 TODO 与方案 | 完成 |
| 2026-11-16 | `ReaderShell` Esc（CallbackShortcuts + Focus）+ 面板「书架」按钮接线 | 完成 |
| 2026-11-16 | 组件测试 `reader_shell_test.dart` 3 条 | 通过 |
| 2026-11-16 | 全量 `flutter test` | 75 条全过 |
| 2026-11-16 | `flutter analyze --no-pub` | 无 error / warning（24 条既有 deprecation info） |
| 2026-11-16 | `flutter build windows --debug` | 构建通过 |
| 2026-11-16 | 集成冒烟首版（真实导入 + 真实 PDF） | 失败：测试 App 进程写 `AppData` 被拒（errno 5） |
| 2026-11-16 | 环境诊断（写探针：工程目录 OK / Temp 拒 / AppData 拒） | 确认为测试框架进程限制，非代码问题；既有 m1_smoke 同样失败 |
| 2026-11-16 | 集成冒烟改为假会话驱动真外壳（真实窗口 + 真实按键） | 通过 |
