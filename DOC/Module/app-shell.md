# 模块：应用壳（app）

- 目录：`lib/app`、`lib/main.dart`
- 所属层：presentation（装配层，无业务逻辑）
- 状态：M0 建设

## 职责

1. 启动入口：`main.dart` → 初始化目录、数据库、依赖注入 → `runApp`。
2. 全局路由：书架为首页，阅读页为二级页；书签模式是阅读页内的浮层状态，**不占路由**。
3. 主题：浅色 / 深色 / 跟随系统，`ThemeData` 唯一来源，阅读区与书架共用。
4. 依赖注入：`ProviderScope`（riverpod）装配 repository / engine 实例，禁止全局可变单例。
5. 全局错误边界与日志初始化。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `main()` | 应用入口 |
| `HomePdfReaderApp` | 根 Widget，持有 `MaterialApp.router` |
| `AppRouter` | `go_router` 配置；路由名 `library`（`/`）、`scan`（`/scan`）、`reader`（`/reader/:documentId`） |
| `AppTheme` | `light` / `dark` / `ThemeData` 构建函数 |

## 依赖关系

- 依赖：`data/repos`（注入点）、`core/storage`（启动期路径初始化）、`features/*/presentation`（路由目标）
- 被依赖：无（最外层）
- 禁止：不直接调用 `pdfrx`；不写 SQL；不含业务规则。

## 约束

- 路由参数只传 `documentId`，其余状态由仓库读取，保证杀进程后行为一致。
- 书签模式为阅读页内部状态（`ReaderMode.reading / bookmarks`），返回键优先退出书签模式，再退出阅读页。
- EPUB 与 PDF 都能进入阅读页：`/reader/:id` 由 `ReaderHostPage` 按 `documents.format` 分流，
  EPUB 走分页阅读页；不再有「阅读页待做」提示。

## 验证

- 冷启动进入书架；深链 `/reader/:id` 能按格式打开 PDF / EPUB 阅读页；`flutter analyze` 零 error。
