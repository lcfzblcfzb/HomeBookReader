# 模块：标注（features/annotations）

- 目录：`lib/features/annotations/{presentation,application,widgets}`
- 所属层：presentation + application
- 状态：未开工（M5，依赖 M0 S2 结论）

## 职责

1. 文本选择层：长按选词、拖拽起止点、跨行选择；跨页按页拆分。
2. 选择结果 → 逐行归一化矩形 + 文字快照 → 一个事务写入 `highlights`。
3. 高亮绘制层：自绘 overlay，与页面共用同一变换矩阵（不各自计算）。
4. 高亮点击 → 心得弹层（查看/编辑/删除）；重叠按最新优先命中。
5. 标注列表：按页序，点击跳转并闪烁定位。
6. 扫描件降级：`has_text_layer = 0` 时禁用选择并提示。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `SelectionLayer` | 文本选择交互（仅文字层文档启用） |
| `HighlightOverlay` | 高亮绘制（输入当前页 `pageIndex` + 调用方变换） |
| `AnnotationsController` | `addSelection(...)`、`list(pageIndex)`、`updateNote(...)`、`remove(...)` |
| `NoteSheet` | 心得编辑底部弹层（自动保存草稿） |

## 依赖关系

- 依赖：`core/pdf`（逐行文本与矩形）、`core/geometry`（归一化与跨页拆分）、`data/repos: HighlightRepository`
- 被依赖：`features/reader`（叠加在页面层之上，工具栏之下）
- 禁止：高亮层自行计算页面缩放/偏移；不得从屏幕坐标直接入库。

## 约束

- 对齐验收：100% / 200% / 400% 缩放不越行、不压字。
- 非法数据（空 rects、越界、页数不匹配）丢弃并记日志，不崩溃。
- 配色固定 4 色（D3），不支持自定义。

## 验证

- 单测：坐标往返、跨页拆分、越界裁剪、缩放投影一致性；手工：多缩放档目测对齐。
