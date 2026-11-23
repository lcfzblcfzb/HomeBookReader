import 'dart:ui' as ui;

import 'pdf_models.dart';

/// PDF 引擎抽象：除 [PdfEngine] 实现外，其他层不得依赖 pdfrx。
abstract interface class PdfEngine {
  /// 打开本地文件；失败抛 [PdfOpenException]。
  Future<PdfDocumentHandle> open(String absolutePath);
}

/// 已打开的文档句柄。
abstract interface class PdfDocumentHandle {
  /// 页数。
  int get pageCount;

  /// 是否具备可用文字层（扫描件为 false）。首次调用可能触发探测。
  Future<bool> hasTextLayer();

  /// 指定页尺寸（pt，旋转后）。
  Future<PageSize> pageSize(int pageIndex);

  /// 渲染指定页为位图，宽度为 [pixelWidth] 像素，高度按纵横比换算。
  ///
  /// 返回的 `ui.Image` 由调用方负责 `dispose`。
  Future<ui.Image> renderPage(int pageIndex, {required int pixelWidth});

  /// 逐行文本（含字符范围与归一化矩形）。无文字层时返回空列表。
  Future<List<PdfTextLine>> textLines(int pageIndex);

  /// 目录树；无 outline 时返回空列表。
  Future<List<PdfOutlineNode>> outline();

  Future<void> dispose();
}
