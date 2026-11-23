# 模块：几何与坐标（core/geometry）

- 目录：`lib/core/geometry`
- 所属层：core（纯 Dart，不依赖 Flutter）
- 状态：M0 建设

## 职责

1. 定义全项目唯一的归一化坐标值对象：以「页面显示框」左上角为原点，x 向右、y 向下，取值 `[0,1]`。
2. 归一化 ↔ 像素/PDF 用户空间的双向换算。
3. 跨页选择按页拆分矩形集合。
4. 合法性校验：越界裁剪、NaN/Infinity 拒绝、精度归一（6 位小数 + clamp）。

## 对外接口

| 名称 | 说明 |
| --- | --- |
| `PagePoint(x, y)` | 页内归一化点，`clamp` 到 `[0,1]` |
| `PageRect(left, top, right, bottom)` | 页内归一化矩形；`fromLTRB` / `fromPixels` / `toPixels(size)` / `round6()` |
| `SelectionSplitter.split(...)` | 输入多行命中，输出按页分组的 `PageRects` |
| `PageRectJson` | `[x0,y0,x1,y1]` 与 `PageRect` 的互转（入库格式） |

## 依赖关系

- 依赖：仅 `dart:math`（不得 import `package:flutter/*`）
- 被依赖：`core/pdf`、`features/reader`、`features/annotations`、`data/repos`
- 说明：`dart:ui` 的 `Rect` 只在 presentation 层做临时转换，不进入 domain 数据。

## 约束

- 精度：入库前 `round(6)` 后 `clamp(0,1)`；反算像素允许 ±1px 误差。
- 渲染一致性：同一矩形在 100% / 200% / 400% 缩放下，反算 PDF 用户空间误差 < 1e-3。
- 旋转本期不支持，`PageRect` 预留 `rotation` 快照字段但恒为 0。

## 验证

- `test/core/geometry/`：随机矩形往返一致性、越界裁剪、跨页拆分顺序、JSON 序列化对称性；覆盖率目标 ≥ 90%。
