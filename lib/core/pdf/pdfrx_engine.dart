import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart' as pdfrx;

import '../geometry/page_rect.dart';
import 'pdf_engine.dart';
import 'pdf_models.dart';

/// 基于 pdfrx（PDFium）的 [PdfEngine] 实现。
///
/// 约定：pdfrx 的类型只在本文件内出现，对外只暴露 domain 模型。
class PdfrxEngine implements PdfEngine {
  const PdfrxEngine();

  @override
  Future<PdfDocumentHandle> open(String absolutePath) async {
    try {
      final document = await pdfrx.PdfDocument.openFile(absolutePath);
      return _PdfrxDocumentHandle(document);
    } on pdfrx.PdfPasswordException catch (e) {
      throw PdfOpenException(PdfFailureKind.encrypted, e.toString());
    } on pdfrx.PdfException catch (e) {
      throw PdfOpenException(PdfFailureKind.corrupted, e.toString());
    } catch (e) {
      throw PdfOpenException(PdfFailureKind.unknown, e.toString());
    }
  }
}

class _PdfrxDocumentHandle implements PdfDocumentHandle {
  _PdfrxDocumentHandle(this._document);

  final pdfrx.PdfDocument _document;
  bool? _hasTextLayer;

  @override
  int get pageCount => _document.pages.length;

  @override
  Future<bool> hasTextLayer() async {
    final cached = _hasTextLayer;
    if (cached != null) return cached;
    final probeCount = pageCount < 3 ? pageCount : 3;
    var found = false;
    for (var i = 0; i < probeCount; i++) {
      try {
        final text = await _document.pages[i].loadText();
        final content = text?.fullText.trim() ?? '';
        if (content.length >= 8) {
          found = true;
          break;
        }
      } catch (_) {
        // 单页探测失败不影响整体判定，继续探测下一页。
      }
    }
    _hasTextLayer = found;
    return found;
  }

  @override
  Future<PageSize> pageSize(int pageIndex) async {
    final page = _page(pageIndex);
    return PageSize(page.width, page.height);
  }

  @override
  Future<ui.Image> renderPage(int pageIndex, {required int pixelWidth}) async {
    final page = _page(pageIndex);
    final fullWidth = pixelWidth.toDouble();
    final fullHeight = fullWidth * page.height / page.width;
    final image = await page.render(
      fullWidth: fullWidth,
      fullHeight: fullHeight,
      backgroundColor: 0xFFFFFFFF,
    );
    if (image == null) {
      throw PdfOpenException(PdfFailureKind.unknown, '第 ${pageIndex + 1} 页渲染失败');
    }
    try {
      return await image.createImage();
    } finally {
      image.dispose();
    }
  }

  @override
  Future<List<PdfTextLine>> textLines(int pageIndex) async {
    final page = _page(pageIndex);
    final pageWidth = page.width;
    final pageHeight = page.height;
    final structured = await page.loadStructuredText();
    final text = structured.fullText;
    final rects = structured.charRects;

    PageRect? toUnit(pdfrx.PdfRect r) {
      final rect = PageRect.fromPixels(
        left: r.left,
        top: r.top,
        right: r.right,
        bottom: r.bottom,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );
      return rect.isEmpty ? null : rect.roundTo6();
    }

    // pdfrx 的 fullText 与 charRects 一一对应，且已按行插入 '\n'；按 '\n' 切行即可。
    final lines = <PdfTextLine>[];
    var lineStart = 0;
    for (var i = 0; i <= text.length; i++) {
      final atEnd = i == text.length;
      if (!atEnd && text.codeUnitAt(i) != 0x0A) continue;
      final raw = text.substring(lineStart, i);
      final content = raw.trim();
      if (content.isNotEmpty) {
        final charRects = <PageRect>[];
        PageRect? bounds;
        for (var j = lineStart; j < i && j < rects.length; j++) {
          final rect = toUnit(rects[j]);
          if (rect == null) continue;
          charRects.add(rect);
          bounds = bounds == null ? rect : bounds.union(rect);
        }
        if (bounds != null) {
          lines.add(
            PdfTextLine(
              text: content,
              start: lineStart + raw.indexOf(content),
              end: lineStart + raw.indexOf(content) + content.length,
              bounds: bounds.roundTo6(),
              charRects: charRects,
            ),
          );
        }
      }
      lineStart = i + 1;
    }
    return lines;
  }

  @override
  Future<List<PdfOutlineNode>> outline() async {
    final nodes = await _document.loadOutline();
    return _convertOutline(nodes, 1);
  }

  List<PdfOutlineNode> _convertOutline(List<pdfrx.PdfOutlineNode> nodes, int level) {
    final result = <PdfOutlineNode>[];
    for (final node in nodes) {
      final pageNumber = node.dest?.pageNumber;
      result.add(
        PdfOutlineNode(
          title: node.title,
          level: level,
          pageIndex: pageNumber == null ? -1 : pageNumber - 1,
          children: _convertOutline(node.children, level + 1),
        ),
      );
    }
    return result;
  }

  @override
  Future<void> dispose() => _document.dispose();

  pdfrx.PdfPage _page(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) {
      throw RangeError.range(pageIndex, 0, pageCount - 1, 'pageIndex');
    }
    return _document.pages[pageIndex];
  }
}
