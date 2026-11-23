# 模块：EPUB 分页阅读（features/reader + core/ebook）

- 目录：`lib/features/reader/application/epub_*`、`lib/features/reader/presentation/epub_reader_page.dart`、
  `lib/features/reader/widgets/typography_settings_panel.dart`、`lib/core/ebook/epub_*`
- 所属层：application + presentation（分页引擎）/ core（包与内容解析、排版参数）
- 状态：M1-016 第一轮（分页阅读、跨章、目录/书签、字号行距、位置恢复）

## 职责

1. 打开 EPUB：只解析容器 / OPF / spine，不排整本；正文按章懒解析。
2. 分页：按当前可用宽高、字号、行距、页边距把单章切成页，页面按排版结果绝对定位渲染。
3. 翻页：左侧 1/3 上一页、右侧 1/3 下一页；跨章连续；全书末尾提示。
4. 定位：目录 `href + fragment`、书签 `position`、上次进度都换算成「章序号 + 章内字符偏移」。
5. 排版设置：字号 5 档、行距 2 档，持久化到 `app_meta`；改档位整本重排并落回同一段。
6. 缓存：章节运行态（内容 + 排版）容量 3；图片尺寸与字节各有小缓存。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `EpubReaderController` | 实现 `ReaderSession`：`open()`、`setViewport(Size)`、`setTypography(t)`、`currentPage`、`position`、`flushProgress()` |
| `ReaderSession` / `ReaderPanelTab` | 阅读页外壳依赖的最小会话接口；页签含 `bookmarks` / `toc` / `typography` |
| `EpubPaginator` | 单章分页：`paginate()`、`onPage` 渐进通知、`isCancelled` 取消 |
| `EpubChapterLayout` | 页列表、完成标记、错误、`pageIndexForChar` 二分定位 |
| `EpubPage` / `EpubPageItem` | 页与页内项（文字片段 / 图片 / 分隔线），含 `spacingBefore` 与页起始字符 |
| `EpubTypography` | 字号 / 行距档位、页边距、标题倍率、`copyWith` |
| `EpubSession` | `open`、`readChapter`、`readResource`、`spineIndexForHref` |
| `EpubContentParser` | XHTML → 块模型（标题/段落/列表/引用/图片/分隔线 + 行内样式 + 锚点） |
| `TypographySettingsPanel` | 独立排版设置组件，只依赖 `value` + `onChanged`，便于从面板搬走 |

## 依赖关系

- 依赖：`core/ebook`（包解析、内容、排版参数）、`data/repos`（Document / Progress / Bookmark / Toc / ReaderTypography）、`core/storage`
- 被依赖：`ReaderHostPage` 按 `documents.format == 'epub'` 选择 `EpubReaderPage`；`ReaderShell` 承载入口与面板
- 禁止：启动即排整本；把 EPUB 位置写进 `page_index`；在 UI 里重新解析 XHTML。

## 约束

- 进度公式 `position = (chapterIndex + currentChar / chapterCharCount) / chapterCount`，
  与字号、屏幕、横竖屏无关。
- 章节缓存 3 章；视口 / 字号 / 行距变化时整体失效并重排当前章。
- 每页通过 `onPage` 通知并让出事件循环；大章节单章内渐进排版。
- 定位期间 `currentPage` 返回 null（加载态），不先显示章首。
- 章内位置取页起始字符；合成前缀（缩进、项目符号）不计入进度字符。
- 图片等比缩放、居中；整张放不下移到下一页；超过页高按页高等比缩小。
- 渲染与测量共用 `EpubBlockStyle` 与固定 `StrutStyle`，并关闭系统字体缩放。

## 验证

- `test/core/ebook/epub_session_test.dart`、`epub_content_test.dart`、`epub_paginator_test.dart`。
- `test/features/reader/epub_reader_controller_test.dart`：真实 EPUB 上的翻页、跨章、末尾提示、
  目录 fragment 跳转、书签往返、退出重进恢复、字号重排、横竖屏切换。
- Android 模拟器（Pixel 5 API 30）手工复核：导入、阅读、翻页分区、目录跳转、返回键、
  字号重排、横竖屏、退出重进均通过；真机字体观感与手势返回待供应商设备复核。
