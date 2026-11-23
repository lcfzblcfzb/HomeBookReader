import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

/// 正文块类型；排版样式由分页引擎按类型决定。
enum EpubBlockKind {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  listItem,
  quote,
  image,
  divider,
}

/// 一段行内文字及其样式。
@immutable
class EpubTextRun {
  const EpubTextRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.code = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool code;

  EpubTextRun mergeStyle({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? code,
  }) => EpubTextRun(
    text,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    code: code ?? this.code,
  );
}

/// 一个排版块。文字块与图片块共用同一类型，按 [kind] 取用字段。
@immutable
class EpubBlock {
  const EpubBlock({
    required this.kind,
    required this.startChar,
    this.runs = const <EpubTextRun>[],
    this.listLevel = 1,
    this.ordered = false,
    this.listIndex = 1,
    this.imageHref,
    this.imageAlt,
  });

  final EpubBlockKind kind;

  /// 本章纯文本中的起始字符偏移（不含排版用的缩进/项目符号）。
  final int startChar;
  final List<EpubTextRun> runs;

  /// 列表层级，1 为最外层。
  final int listLevel;
  final bool ordered;
  final int listIndex;

  /// 图片在包内的相对路径（已相对 OPF 目录归一化）。
  final String? imageHref;
  final String? imageAlt;

  bool get isText => kind != EpubBlockKind.image && kind != EpubBlockKind.divider;

  /// 纯文本长度（图片 / 分隔线为 0）。
  int get charCount => runs.fold<int>(0, (sum, run) => sum + run.text.length);

  String get plainText => runs.map((run) => run.text).join();
}

/// 解析后的单章内容。
@immutable
class EpubChapterContent {
  const EpubChapterContent({
    required this.href,
    required this.blocks,
    required this.anchors,
    required this.charCount,
  });

  final String href;
  final List<EpubBlock> blocks;

  /// 片段名 → 本章纯文本字符偏移。
  final Map<String, int> anchors;
  final int charCount;

  /// 把 fragment 换算成字符偏移；找不到时回落到章首。
  int offsetOfFragment(String? fragment) {
    if (fragment == null || fragment.isEmpty) return 0;
    return anchors[fragment] ?? 0;
  }
}

/// 单章解析失败；[reason] 可直接展示。
class EpubContentException implements Exception {
  const EpubContentException(this.reason);

  final String reason;

  @override
  String toString() => 'EpubContentException($reason)';
}

/// XHTML → 排版块。
///
/// 只保留阅读需要的结构：标题、段落、列表、引用、图片、分隔线，以及
/// 粗体 / 斜体 / 下划线 / 等宽。脚本、样式、SVG、导航一律跳过。
abstract final class EpubContentParser {
  static EpubChapterContent parse(
    String xhtml, {
    required String chapterHref,
  }) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(
        xhtml,
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
    } catch (_) {
      throw const EpubContentException('本章内容解析失败');
    }

    XmlElement? body;
    for (final element in document.descendantElements) {
      if (element.name.local == 'body') {
        body = element;
        break;
      }
    }
    body ??= document.rootElement;

    final builder = _ChapterBuilder(chapterHref);
    builder.walkContainer(body);
    return builder.build();
  }
}

class _ChapterBuilder {
  _ChapterBuilder(this.chapterHref);

  final String chapterHref;
  final List<EpubBlock> _blocks = <EpubBlock>[];
  final Map<String, int> _anchors = <String, int>{};
  int _totalChars = 0;

  EpubChapterContent build() => EpubChapterContent(
    href: chapterHref,
    blocks: List<EpubBlock>.unmodifiable(_blocks),
    anchors: Map<String, int>.unmodifiable(_anchors),
    charCount: _totalChars,
  );

  /// 容器：逐个子节点判断块级 / 行内，行内内容攒成段落。
  void walkContainer(XmlElement element) {
    final inline = <EpubTextRun>[];
    final images = <_InlineImage>[];

    void flush() {
      _addTextBlock(
        _paragraphKind(),
        inline,
        images,
        listLevel: _listLevel,
        ordered: _ordered,
        listIndex: _listIndex,
      );
      inline.clear();
      images.clear();
    }

    for (final node in element.children) {
      if (node is XmlText) {
        final text = _normalizeInline(node.value);
        if (text.isNotEmpty) inline.add(EpubTextRun(text));
        continue;
      }
      if (node is! XmlElement) continue;
      _recordAnchor(node);
      if (_isBlockElement(node)) {
        flush();
        _walkBlock(node);
      } else {
        _collectInline(node, inline, images, const _InlineStyle());
      }
    }
    flush();
  }

  EpubBlockKind _paragraphKind() => _quoteDepth > 0
      ? EpubBlockKind.quote
      : EpubBlockKind.paragraph;

  int _listLevel = 1;
  bool _ordered = false;
  int _listIndex = 1;
  int _quoteDepth = 0;

  void _walkBlock(XmlElement element) {
    switch (element.name.local) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(element.name.local.substring(1));
        _addInlineBlock(EpubBlockKind.values[level], element);
        break;
      case 'p':
        _addInlineBlock(_paragraphKind(), element);
        break;
      case 'ul':
      case 'ol':
        _walkList(element, ordered: element.name.local == 'ol');
        break;
      case 'blockquote':
        _quoteDepth++;
        walkContainer(element);
        _quoteDepth--;
        break;
      case 'pre':
        final runs = _inlineRuns(element);
        if (runs.isNotEmpty) {
          _addTextBlock(
            _paragraphKind(),
            runs
                .map(
                  (run) => EpubTextRun(run.text, code: true, italic: false),
                )
                .toList(),
            const <_InlineImage>[],
          );
        }
        break;
      case 'img':
        final image = _imageOf(element);
        if (image != null) _addImage(image);
        break;
      case 'image':
        final href =
            element.getAttribute('xlink:href') ??
            element.getAttribute('href');
        if (href != null && href.isNotEmpty) {
          _addImage(_InlineImage(_resolve(href), element.getAttribute('alt')));
        }
        break;
      case 'hr':
        _blocks.add(
          EpubBlock(kind: EpubBlockKind.divider, startChar: _totalChars),
        );
        break;
      case 'table':
        _walkTable(element);
        break;
      case 'tr':
        _walkTableRow(element);
        break;
      case 'td':
      case 'th':
        _addInlineBlock(EpubBlockKind.paragraph, element);
        break;
      case 'nav':
      case 'script':
      case 'style':
      case 'svg':
      case 'head':
        // 导航、脚本、样式、矢量图不进入正文。
        return;
      case 'li':
        final inline = <EpubTextRun>[];
        final images = <_InlineImage>[];
        _collectListItem(element, inline, images);
        _addTextBlock(
          EpubBlockKind.listItem,
          inline,
          images,
          listLevel: _listLevel,
          ordered: _ordered,
          listIndex: _listIndex,
        );
        break;
      default:
        walkContainer(element);
        break;
    }
  }

  void _walkList(XmlElement list, {required bool ordered}) {
    final outerLevel = _listLevel;
    final outerOrdered = _ordered;
    final outerIndex = _listIndex;
    _listLevel = outerLevel;
    _ordered = ordered;
    var index = 1;
    for (final item in list.childElements.where((e) => e.name.local == 'li')) {
      _recordAnchor(item);
      _listIndex = index++;
      final inline = <EpubTextRun>[];
      final images = <_InlineImage>[];
      _collectListItem(item, inline, images);
      _addTextBlock(
        EpubBlockKind.listItem,
        inline,
        images,
        listLevel: _listLevel,
        ordered: _ordered,
        listIndex: _listIndex,
      );
      for (final nested in item.childElements.where(
        (e) => e.name.local == 'ul' || e.name.local == 'ol',
      )) {
        _listLevel++;
        _walkList(nested, ordered: nested.name.local == 'ol');
        _listLevel--;
      }
    }
    _listLevel = outerLevel;
    _ordered = outerOrdered;
    _listIndex = outerIndex;
  }

  /// li 自身的行内内容；嵌套列表交给调用方递归。
  void _collectListItem(
    XmlElement item,
    List<EpubTextRun> out,
    List<_InlineImage> images,
  ) {
    _collectInlineChildren(
      item,
      out,
      images,
      const _InlineStyle(),
      skipNestedLists: true,
    );
  }

  void _walkTable(XmlElement table) {
    for (final row in table.descendantElements.where(
      (e) => e.name.local == 'tr',
    )) {
      _walkTableRow(row);
    }
  }

  void _walkTableRow(XmlElement row) {
    final cells = <String>[];
    for (final cell in row.childElements.where(
      (e) => e.name.local == 'td' || e.name.local == 'th',
    )) {
      _recordAnchor(cell);
      final text = _inlineRuns(cell).map((run) => run.text).join().trim();
      if (text.isNotEmpty) cells.add(text);
    }
    if (cells.isEmpty) return;
    _addTextBlock(
      EpubBlockKind.paragraph,
      <EpubTextRun>[EpubTextRun(cells.join('    '))],
      const <_InlineImage>[],
    );
  }

  void _addTextBlock(
    EpubBlockKind kind,
    List<EpubTextRun> rawRuns,
    List<_InlineImage> images, {
    int listLevel = 1,
    bool ordered = false,
    int listIndex = 1,
  }) {
    final runs = _normalizeRuns(rawRuns);
    if (runs.isNotEmpty) {
      _blocks.add(
        EpubBlock(
          kind: kind,
          startChar: _totalChars,
          runs: runs,
          listLevel: listLevel,
          ordered: ordered,
          listIndex: listIndex,
        ),
      );
      _totalChars += runs.fold<int>(0, (sum, run) => sum + run.text.length);
    }
    for (final image in images) {
      _addImage(image);
    }
  }

  void _addImage(_InlineImage image) {
    _blocks.add(
      EpubBlock(
        kind: EpubBlockKind.image,
        startChar: _totalChars,
        imageHref: image.href,
        imageAlt: image.alt,
      ),
    );
  }

  void _recordAnchor(XmlElement element) {
    final id = element.getAttribute('id') ?? element.getAttribute('name');
    if (id == null || id.isEmpty) return;
    _anchors.putIfAbsent(id, () => _totalChars);
  }

  List<EpubTextRun> _inlineRuns(XmlElement element) {
    final runs = <EpubTextRun>[];
    final images = <_InlineImage>[];
    _collectInlineChildren(
      element,
      runs,
      images,
      const _InlineStyle(),
      skipNestedLists: false,
    );
    return runs;
  }

  /// 解析一个块的行内内容；内嵌图片单独成图片块，不丢。
  void _addInlineBlock(EpubBlockKind kind, XmlElement element) {
    final runs = <EpubTextRun>[];
    final images = <_InlineImage>[];
    _collectInlineChildren(
      element,
      runs,
      images,
      const _InlineStyle(),
      skipNestedLists: false,
    );
    _addTextBlock(kind, runs, images);
  }

  void _collectInlineChildren(
    XmlElement element,
    List<EpubTextRun> out,
    List<_InlineImage> images,
    _InlineStyle style, {
    required bool skipNestedLists,
  }) {
    for (final node in element.children) {
      if (node is XmlText) {
        final text = _normalizeInline(node.value);
        if (text.isNotEmpty) {
          out.add(
            EpubTextRun(
              text,
              bold: style.bold,
              italic: style.italic,
              underline: style.underline,
              code: style.code,
            ),
          );
        }
        continue;
      }
      if (node is! XmlElement) continue;
      if (skipNestedLists &&
          (node.name.local == 'ul' || node.name.local == 'ol')) {
        continue;
      }
      _recordAnchor(node);
      _collectInline(node, out, images, style);
    }
  }

  void _collectInline(
    XmlElement element,
    List<EpubTextRun> out,
    List<_InlineImage> images,
    _InlineStyle style,
  ) {
    switch (element.name.local) {
      case 'br':
        out.add(
          EpubTextRun(
            '\n',
            bold: style.bold,
            italic: style.italic,
            underline: style.underline,
            code: style.code,
          ),
        );
      case 'b':
      case 'strong':
        _collectInlineChildren(
          element,
          out,
          images,
          style.copyWith(bold: true),
          skipNestedLists: false,
        );
      case 'i':
      case 'em':
      case 'cite':
        _collectInlineChildren(
          element,
          out,
          images,
          style.copyWith(italic: true),
          skipNestedLists: false,
        );
      case 'u':
        _collectInlineChildren(
          element,
          out,
          images,
          style.copyWith(underline: true),
          skipNestedLists: false,
        );
      case 'code':
      case 'tt':
      case 'kbd':
      case 'samp':
        _collectInlineChildren(
          element,
          out,
          images,
          style.copyWith(code: true),
          skipNestedLists: false,
        );
      case 'img':
        final image = _imageOf(element);
        if (image != null) images.add(image);
      case 'image':
        final href =
            element.getAttribute('xlink:href') ??
            element.getAttribute('href');
        if (href != null && href.isNotEmpty) {
          images.add(_InlineImage(_resolve(href), element.getAttribute('alt')));
        }
      case 'script':
      case 'style':
      case 'svg':
      case 'nav':
        return;
      default:
        _collectInlineChildren(
          element,
          out,
          images,
          style,
          skipNestedLists: false,
        );
    }
  }

  _InlineImage? _imageOf(XmlElement element) {
    final src = element.getAttribute('src');
    if (src == null || src.trim().isEmpty) return null;
    return _InlineImage(_resolve(src), element.getAttribute('alt'));
  }

  String _resolve(String src) => _normalizePath(chapterHref, src);

  static String _normalizePath(String chapterHref, String src) {
    final value = _decode(src).replaceAll(r'\', '/');
    if (value.startsWith('/')) return value.substring(1);
    final slash = chapterHref.lastIndexOf('/');
    final dir = slash < 0 ? '' : chapterHref.substring(0, slash + 1);
    final joined = '$dir$value';
    final parts = <String>[];
    for (final part in joined.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
        continue;
      }
      parts.add(part);
    }
    return parts.join('/');
  }

  static String _decode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  /// 折叠空白：文本节点里的换行 / 连续空格按 HTML 规则压成一个空格。
  static String _normalizeInline(String value) =>
      value.replaceAll(RegExp(r'[\s\u00A0]+'), ' ');

  /// 合并同样式 run，去掉段首段尾空白。
  static List<EpubTextRun> _normalizeRuns(List<EpubTextRun> runs) {
    final merged = <EpubTextRun>[];
    for (final run in runs) {
      if (run.text.isEmpty) continue;
      if (merged.isNotEmpty) {
        final last = merged.last;
        if (last.bold == run.bold &&
            last.italic == run.italic &&
            last.underline == run.underline &&
            last.code == run.code) {
          merged[merged.length - 1] = last.copyText(last.text + run.text);
          continue;
        }
      }
      merged.add(run);
    }
    if (merged.isEmpty) return const <EpubTextRun>[];

    // 段首去空白，段尾去空白；中间连续空格压成一个。
    for (var i = 0; i < merged.length; i++) {
      var text = merged[i].text.replaceAll(RegExp(r' {2,}'), ' ');
      if (i == 0) text = text.replaceFirst(RegExp(r'^ +'), '');
      if (i == merged.length - 1) text = text.replaceFirst(RegExp(r' +$'), '');
      merged[i] = merged[i].copyText(text);
    }
    return merged.where((run) => run.text.isNotEmpty).toList(growable: false);
  }

  static bool _isBlockElement(XmlElement element) => const <String>{
    'p',
    'div',
    'section',
    'article',
    'main',
    'header',
    'footer',
    'aside',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'table',
    'tr',
    'td',
    'th',
    'figure',
    'figcaption',
    'hr',
    'img',
    'image',
    'nav',
    'script',
    'style',
    'svg',
  }.contains(element.name.local);
}

extension on EpubTextRun {
  EpubTextRun copyText(String text) => EpubTextRun(
    text,
    bold: bold,
    italic: italic,
    underline: underline,
    code: code,
  );
}

class _InlineStyle {
  const _InlineStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.code = false,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool code;

  _InlineStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? code,
  }) => _InlineStyle(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    code: code ?? this.code,
  );
}

class _InlineImage {
  const _InlineImage(this.href, this.alt);

  final String href;
  final String? alt;
}
