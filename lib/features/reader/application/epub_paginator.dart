import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/ebook/epub_content.dart';
import '../../../core/ebook/epub_typography.dart';
import '../presentation/reader_ui_config.dart';

/// 图片原始像素尺寸；排版只需要宽高比。
class EpubImageInfo {
  const EpubImageInfo(this.width, this.height);

  final double width;
  final double height;

  double get aspectRatio => width <= 0 || height <= 0 ? 1 : width / height;
}

/// 页面里的一项：文字片段 / 图片 / 分隔线。
sealed class EpubPageItem {
  const EpubPageItem({required this.height, required this.spacingBefore});

  final double height;

  /// 与上一项之间的空白；页首为 0。
  final double spacingBefore;
}

/// 文字片段：按行边界切开的一段文本。
class EpubTextItem extends EpubPageItem {
  const EpubTextItem({
    required super.height,
    required super.spacingBefore,
    required this.block,
    required this.runs,
    required this.lineHeight,
  });

  final EpubBlock block;
  final List<EpubTextRun> runs;
  final double lineHeight;
}

class EpubImageItem extends EpubPageItem {
  const EpubImageItem({
    required super.height,
    required super.spacingBefore,
    required this.href,
    required this.width,
    this.alt,
  });

  final String href;
  final double width;
  final String? alt;
}

class EpubDividerItem extends EpubPageItem {
  const EpubDividerItem({required super.spacingBefore})
    : super(height: 1);
}

/// 排版后的一页。
class EpubPage {
  const EpubPage({
    required this.chapterIndex,
    required this.pageInChapter,
    required this.startChar,
    required this.items,
  });

  final int chapterIndex;
  final int pageInChapter;

  /// 本页起始字符在本章纯文本中的偏移，用于进度与重排恢复。
  final int startChar;
  final List<EpubPageItem> items;
}

/// 单章排版结果；渐进排版时会逐步追加 [pages]。
class EpubChapterLayout {
  EpubChapterLayout({required this.chapterIndex, required this.charCount});

  int chapterIndex;
  int charCount;
  final List<EpubPage> pages = <EpubPage>[];
  bool complete = false;

  /// 解析失败时的中文提示；此时 [pages] 为空。
  String? error;

  /// 包含 [charOffset] 的页；排版尚未覆盖时返回最后一页。
  int pageIndexForChar(int charOffset) {
    if (pages.isEmpty) return 0;
    var low = 0;
    var high = pages.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (pages[mid].startChar <= charOffset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}

/// 把单章内容按当前字号 / 行距 / 视口切成页。
///
/// 逐块测量，每完成一页通过 [onPage] 通知并让出事件循环，避免大章节
/// 一次性占用主线程；[isCancelled] 变化后立即停止。
class EpubPaginator {
  EpubPaginator({
    required this.content,
    required this.chapterIndex,
    required this.typography,
    required this.contentWidth,
    required this.contentHeight,
    required this.loadImage,
    this.layout,
    this.onPage,
    this.isCancelled,
  });

  final EpubChapterContent content;
  final int chapterIndex;
  final EpubTypography typography;
  final double contentWidth;
  final double contentHeight;
  final Future<EpubImageInfo?> Function(String href) loadImage;
  final EpubChapterLayout? layout;
  final VoidCallback? onPage;
  final bool Function()? isCancelled;

  late final EpubChapterLayout _layout =
      layout ??
      EpubChapterLayout(
        chapterIndex: chapterIndex,
        charCount: content.charCount,
      );
  final List<EpubPageItem> _items = <EpubPageItem>[];
  double _remaining = 0;
  int _pageStartChar = 0;
  int _pageInChapter = 0;

  /// 当前页已用高度（用于测试与调试）。
  double get usedHeight => contentHeight - _remaining;

  Future<EpubChapterLayout> paginate() async {
    _layout.pages.clear();
    _layout.complete = false;
    _pageStartChar = 0;
    _pageInChapter = 0;
    _items.clear();
    _remaining = contentHeight;

    if (content.blocks.isEmpty) {
      _flushPage(nextStart: 0);
      _layout.complete = true;
      return _layout;
    }

    for (var index = 0; index < content.blocks.length; index++) {
      if (_cancelled) return _layout;
      final block = content.blocks[index];
      switch (block.kind) {
        case EpubBlockKind.image:
          await _addImage(block);
        case EpubBlockKind.divider:
          _addDivider(block);
        default:
          _addText(block);
      }
    }
    if (_items.isNotEmpty) {
      _flushPage(nextStart: content.charCount);
    }
    _layout.complete = true;
    return _layout;
  }

  bool get _cancelled => isCancelled?.call() ?? false;

  Future<void> _addImage(EpubBlock block) async {
    final href = block.imageHref;
    if (href == null || href.isEmpty) return;
    final info = await loadImage(href);
    if (_cancelled) return;
    if (info == null) return;

    var width = contentWidth;
    var height = width / info.aspectRatio;
    if (height > contentHeight) {
      height = contentHeight;
      width = height * info.aspectRatio;
    }
    final spacing = _spacingBefore(block.kind);
    await _placeItem(
      EpubImageItem(
        height: height,
        spacingBefore: spacing,
        href: href,
        width: width,
        alt: block.imageAlt,
      ),
      nextStart: block.startChar,
    );
  }

  void _addDivider(EpubBlock block) {
    final spacing = _spacingBefore(EpubBlockKind.divider);
    _placeItemSync(
      EpubDividerItem(spacingBefore: spacing),
      nextStart: block.startChar,
    );
  }

  void _addText(EpubBlock block) {
    final style = EpubBlockStyle.of(block.kind, typography);
    final lineHeight = style.fontSize * typography.lineSpacing;
    final prefix = _prefixFor(block);
    final runs = <EpubTextRun>[
      if (prefix.isNotEmpty) EpubTextRun(prefix),
      ...block.runs,
    ];
    final text = runs.map((run) => run.text).join();
    if (text.trim().isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        style: style.textStyle,
        children: runs
            .map((run) => TextSpan(text: run.text, style: style.runStyle(run)))
            .toList(),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      strutStyle: StrutStyle(
        fontSize: style.fontSize,
        height: typography.lineSpacing,
        forceStrutHeight: true,
        leading: 0,
      ),
      textWidthBasis: TextWidthBasis.parent,
    )..layout(maxWidth: contentWidth);
    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) {
      painter.dispose();
      return;
    }
    final tops = <double>[];
    var top = 0.0;
    for (final metric in metrics) {
      tops.add(top);
      top += metric.height;
    }
    double yOfLine(int line) =>
        tops[line.clamp(0, metrics.length - 1)] +
        metrics[line.clamp(0, metrics.length - 1)].height / 2;

    final prefixChars = prefix.length;
    var lineIndex = 0;
    var first = true;
    while (lineIndex < metrics.length) {
      if (_cancelled) {
        painter.dispose();
        return;
      }
      final spacing = first ? _spacingBefore(block.kind) : 0.0;
      final available = _remaining - spacing;
      if (available < lineHeight - 0.01 && _items.isNotEmpty) {
        _flushPage(nextStart: _globalChar(block, lineIndex, painter, yOfLine, prefixChars));
        first = false;
        continue;
      }
      // 至少放一行；页首的段距不挤占第一行。
      var lines = 0;
      var used = 0.0;
      while (lineIndex + lines < metrics.length) {
        final h = metrics[lineIndex + lines].height;
        if (lines > 0 && used + h > available + 0.01) break;
        used += h;
        lines++;
      }
      lines = math.max(1, lines);
      used = 0;
      for (var i = 0; i < lines; i++) {
        used += metrics[lineIndex + i].height;
      }

      final startRaw = lineIndex == 0 ? 0 : _offsetAt(painter, 0, yOfLine(lineIndex));
      final endRaw = lineIndex + lines >= metrics.length
          ? text.length
          : _offsetAt(painter, 0, yOfLine(lineIndex + lines));
      final slice = _sliceRuns(runs, startRaw, endRaw);
      final nextRaw = endRaw;
      final nextGlobal = _globalOffset(block.startChar, nextRaw, prefixChars);

      _placeItemSync(
        EpubTextItem(
          height: used,
          spacingBefore: _items.isEmpty ? 0 : spacing,
          block: block,
          runs: slice,
          lineHeight: lineHeight,
        ),
        nextStart: lineIndex == 0
            ? block.startChar
            : _globalOffset(block.startChar, startRaw, prefixChars),
      );
      lineIndex += lines;
      first = false;
      if (lineIndex < metrics.length) {
        _flushPage(nextStart: nextGlobal);
      }
    }
    painter.dispose();
  }

  void _placeItemSync(EpubPageItem item, {required int nextStart}) {
    var spacing = item.spacingBefore;
    if (_items.isNotEmpty && spacing + item.height > _remaining + 0.01) {
      _flushPage(nextStart: nextStart);
      spacing = 0;
    }
    if (spacing > _remaining) spacing = 0;
    _items.add(_withSpacing(item, spacing));
    _remaining -= spacing + item.height;
  }

  Future<void> _placeItem(EpubPageItem item, {required int nextStart}) async {
    var spacing = item.spacingBefore;
    if (_items.isNotEmpty && spacing + item.height > _remaining + 0.01) {
      _flushPage(nextStart: nextStart);
      spacing = 0;
    }
    if (spacing > _remaining) spacing = 0;
    _items.add(_withSpacing(item, spacing));
    _remaining -= spacing + item.height;
    await Future<void>.delayed(Duration.zero);
  }

  EpubPageItem _withSpacing(EpubPageItem item, double spacing) =>
      switch (item) {
        EpubTextItem() => EpubTextItem(
          height: item.height,
          spacingBefore: spacing,
          block: item.block,
          runs: item.runs,
          lineHeight: item.lineHeight,
        ),
        EpubImageItem() => EpubImageItem(
          height: item.height,
          spacingBefore: spacing,
          href: item.href,
          width: item.width,
          alt: item.alt,
        ),
        EpubDividerItem() => EpubDividerItem(spacingBefore: spacing),
      };

  void _flushPage({required int nextStart}) {
    if (_items.isEmpty && _layout.pages.isNotEmpty) return;
    _layout.pages.add(
      EpubPage(
        chapterIndex: _layout.chapterIndex,
        pageInChapter: _pageInChapter,
        startChar: _pageStartChar,
        items: List<EpubPageItem>.unmodifiable(_items),
      ),
    );
    _items.clear();
    _pageInChapter++;
    _pageStartChar = nextStart;
    _remaining = contentHeight;
    onPage?.call();
  }

  double _spacingBefore(EpubBlockKind kind) {
    if (_items.isEmpty) return 0;
    final base = typography.fontSize;
    return switch (kind) {
      EpubBlockKind.heading1 ||
      EpubBlockKind.heading2 ||
      EpubBlockKind.heading3 ||
      EpubBlockKind.heading4 ||
      EpubBlockKind.heading5 ||
      EpubBlockKind.heading6 => base * 1.1,
      EpubBlockKind.paragraph || EpubBlockKind.quote => base * 0.4,
      EpubBlockKind.listItem => base * 0.2,
      EpubBlockKind.image => base * 0.6,
      EpubBlockKind.divider => base * 0.9,
    };
  }

  /// 预置排版前缀：段首缩进 / 列表符号 / 引用缩进。
  ///
  /// 这些是排版用的合成字符，不计入进度字符偏移。
  String _prefixFor(EpubBlock block) {
    switch (block.kind) {
      case EpubBlockKind.paragraph:
        return '\u3000\u3000';
      case EpubBlockKind.quote:
        return '\u3000';
      case EpubBlockKind.listItem:
        final indent = '\u3000' * (block.listLevel - 1).clamp(0, 4);
        final marker = block.ordered ? '${block.listIndex}. ' : '• ';
        return '$indent$marker';
      default:
        return '';
    }
  }

  int _globalChar(
    EpubBlock block,
    int lineIndex,
    TextPainter painter,
    double Function(int line) yOfLine,
    int prefixChars,
  ) {
    if (lineIndex == 0) return block.startChar;
    final raw = _offsetAt(painter, 0, yOfLine(lineIndex));
    return _globalOffset(block.startChar, raw, prefixChars);
  }

  int _globalOffset(int blockStart, int rawOffset, int prefixChars) =>
      blockStart + math.max(0, rawOffset - prefixChars);

  static int _offsetAt(TextPainter painter, double x, double y) {
    final position = painter.getPositionForOffset(Offset(x, y));
    return position.offset;
  }

  static List<EpubTextRun> _sliceRuns(
    List<EpubTextRun> runs,
    int start,
    int end,
  ) {
    if (start <= 0 && end >= runs.fold<int>(0, (sum, run) => sum + run.text.length)) {
      return List<EpubTextRun>.unmodifiable(runs);
    }
    final out = <EpubTextRun>[];
    var cursor = 0;
    for (final run in runs) {
      final runEnd = cursor + run.text.length;
      if (runEnd <= start) {
        cursor = runEnd;
        continue;
      }
      if (cursor >= end) break;
      final from = math.max(start, cursor) - cursor;
      final to = math.min(end, runEnd) - cursor;
      if (to > from) {
        out.add(
          EpubTextRun(
            run.text.substring(from, to),
            bold: run.bold,
            italic: run.italic,
            underline: run.underline,
            code: run.code,
          ),
        );
      }
      cursor = runEnd;
    }
    return out;
  }
}

/// 块级文本样式：分页测量与页面绘制共用，保证两边一致。
class EpubBlockStyle {
  const EpubBlockStyle({
    required this.fontSize,
    required this.lineSpacing,
    required this.weight,
    required this.color,
    required this.italic,
  });

  final double fontSize;
  final double lineSpacing;
  final FontWeight weight;
  final Color color;
  final bool italic;

  static EpubBlockStyle of(EpubBlockKind kind, EpubTypography typography) {
    final level = switch (kind) {
      EpubBlockKind.heading1 => 1,
      EpubBlockKind.heading2 => 2,
      EpubBlockKind.heading3 => 3,
      EpubBlockKind.heading4 => 4,
      EpubBlockKind.heading5 => 5,
      EpubBlockKind.heading6 => 6,
      _ => 0,
    };
    final scale = level == 0 ? 1.0 : typography.headingScale(level);
    final isHeading = level > 0;
    return EpubBlockStyle(
      fontSize: typography.fontSize * scale,
      lineSpacing: typography.lineSpacing,
      weight: isHeading ? FontWeight.w600 : FontWeight.w400,
      color: switch (kind) {
        EpubBlockKind.quote => ReaderUiConfig.epubQuoteColor,
        _ => ReaderUiConfig.epubTextColor,
      },
      italic: kind == EpubBlockKind.quote,
    );
  }

  TextStyle get textStyle => TextStyle(
    fontSize: fontSize,
    height: lineSpacing,
    fontWeight: weight,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );

  TextStyle runStyle(EpubTextRun run) {
    final code = run.code;
    return TextStyle(
      fontWeight: run.bold ? FontWeight.w700 : weight,
      fontStyle: run.italic || italic ? FontStyle.italic : FontStyle.normal,
      decoration: run.underline ? TextDecoration.underline : null,
      color: code ? ReaderUiConfig.epubQuoteColor : null,
      fontFamily: code ? 'monospace' : null,
    );
  }
}

/// 解码图片取原始尺寸；供控制器缓存。
Future<EpubImageInfo?> decodeEpubImage(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    image = frame.image;
    return EpubImageInfo(image.width.toDouble(), image.height.toDouble());
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}
