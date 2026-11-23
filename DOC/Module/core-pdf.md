# 模块：PDF 引擎（core/pdf）

- 目录：`lib/core/pdf`
- 所属层：core（唯一允许出现 `pdfrx` 的目录）
- 状态：M0 建设

## 职责

1. 打开本地 PDF 文件，暴露页数、页尺寸、页面渲染。
2. 文本提取：按行输出「文本内容 + 字符范围 + 归一化矩形」，供后续划线与摘录使用。
3. outline 读取：标题、层级、目标页（0 基）。
4. 能力探测：是否存在可用文字层、是否加密、是否损坏。

## 对外接口（草案，M0 定稿）

```dart
abstract class PdfEngine {
  Future<PdfDocumentHandle> open(String absolutePath);
}

abstract class PdfDocumentHandle {
  int get pageCount;
  bool get hasTextLayer;
  Future<PageSize> pageSize(int pageIndex);           // PDF 用户空间尺寸（pt）
  Future<Uint8List> renderPage(int pageIndex, double pixelWidth);
  Future<List<PdfTextLine>> textLines(int pageIndex); // 逐行：text / charRanges / rects（归一化）
  Future<PdfTextRange> textInRange(int pageIndex, int start, int end);
  Future<List<PdfOutlineNode>> outline();             // 无 outline 返回空列表
  Future<void> dispose();
}
```

数据类 `PdfTextLine`、`PdfOutlineNode`、`PageSize` 定义在 `pdf_models.dart`，**不含 Flutter 类型**（`dart:ui` 的 `Rect` 也不外泄，统一用 `core/geometry` 的 `PageRect`）。

## 依赖关系

- 依赖：`pdfrx`、`core/geometry`（归一化坐标类型）、`dart:io`
- 被依赖：`data/repos`（文档元数据、文本、目录）、`features/reader`（渲染）、`features/toc`、`features/annotations`
- 反向禁止：`core/pdf` 不感知任何 UI、路由、数据库。

## 约束与风险

- pdfrx 版本在 M0 锁定具体版本号（R3），升级须单独评审；所有 pdfrx 类型在本模块内部转换后即丢弃。
- 归一化基准是「旋转后 crop box」，需在 `pageSize` 与 `textLines` 间保持同一基准，避免标注错位。
- S2 结论若为「逐行矩形不稳定」，本模块需额外提供「字符范围 → 矩形」的自绘替代路径。

## 实现要点

- `textLines` 使用 `page.loadStructuredText()` 的 `fullText` 与 `charRects`（二者严格一一对应，且已按 `\n` 分行）切行，输出行文本、字符范围、行矩形与逐字符矩形；不用 `fragments`（片段/词级，CJK 会被切成单字）。
- 所有矩形在出口处转换为 `PageRect` 并 `roundTo6`，空矩形丢弃。
- `hasTextLayer` 采用前 3 页文本长度 ≥ 8 的启发式判定。

## 验证

- `test/core/geometry` 覆盖坐标换算；样本断言见 `lib/dev/spike_main.dart`（M0 Spike）。
- M0 实测（Windows）：中文样本 10 行/页、304 字符矩形，行文本 `第 1 页 / 共 10 页`；outline 4 节点/2 层；无 outline 与扫描件返回空列表。
