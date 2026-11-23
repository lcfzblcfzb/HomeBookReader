import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'epub_models.dart';
import 'epub_parser.dart';

/// spine 中的一条正文。
class EpubSpineItem {
  const EpubSpineItem({required this.href, required this.mediaType});

  /// 相对 OPF 目录、已归一化的包内路径。
  final String href;
  final String mediaType;

  bool get isHtml =>
      mediaType == 'application/xhtml+xml' || mediaType == 'text/html';
}

/// 一次阅读会话：持有 ZIP 归档，按 spine 顺序读取正文与图片资源。
///
/// 只解析 container / OPF / spine，不解析正文；正文按章懒加载。
class EpubSession {
  EpubSession._({
    required Archive archive,
    required this.opfPath,
    required this.spine,
    required Map<String, String> mediaTypes,
  }) : _archive = archive,
       _mediaTypes = mediaTypes;

  final Archive _archive;
  final String opfPath;
  final List<EpubSpineItem> spine;
  final Map<String, String> _mediaTypes;

  /// 打开并校验 EPUB；失败抛 [EpubInvalidException]（中文原因）。
  static Future<EpubSession> open(File file) async {
    final bytes = await file.readAsBytes();
    return openBytes(bytes);
  }

  static EpubSession openBytes(Uint8List bytes) {
    final archive = EpubParser.validate(bytes);
    final opfPath = _opfPathOf(archive);
    final opfFile = _fileOf(archive, opfPath);
    if (opfFile == null) {
      throw const EpubInvalidException('EPUB 的 OPF 文件不存在');
    }
    final XmlDocument opf;
    try {
      opf = XmlDocument.parse(
        _decodeText(opfFile),
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
    } catch (_) {
      throw const EpubInvalidException('EPUB 的 OPF 文件已损坏');
    }

    final items = <String, _ManifestItem>{};
    final manifest = _firstByLocal(opf, 'manifest');
    if (manifest != null) {
      for (final element in manifest.childElements.where(
        (e) => e.name.local == 'item',
      )) {
        final id = element.getAttribute('id');
        final href = element.getAttribute('href');
        if (id == null || href == null || href.isEmpty) continue;
        items[id] = _ManifestItem(
          href: _resolve(opfPath, _decode(href)),
          mediaType: element.getAttribute('media-type') ?? '',
          properties: element.getAttribute('properties') ?? '',
        );
      }
    }

    final spine = <EpubSpineItem>[];
    final spineElement = _firstByLocal(opf, 'spine');
    if (spineElement != null) {
      for (final ref in spineElement.childElements.where(
        (e) => e.name.local == 'itemref',
      )) {
        final id = ref.getAttribute('idref');
        final item = id == null ? null : items[id];
        if (item == null) continue;
        final entry = EpubSpineItem(href: item.href, mediaType: item.mediaType);
        if (!entry.isHtml) continue;
        spine.add(entry);
      }
    }
    if (spine.isEmpty) {
      // 个别书缺少可用 spine：按 manifest 顺序退回正文 XHTML（跳过导航文档）。
      for (final item in items.values) {
        final entry = EpubSpineItem(href: item.href, mediaType: item.mediaType);
        if (entry.isHtml && !item.isNavigation) spine.add(entry);
      }
    }
    if (spine.isEmpty) {
      throw const EpubInvalidException('EPUB 没有可阅读的正文');
    }

    return EpubSession._(
      archive: archive,
      opfPath: opfPath,
      spine: spine,
      mediaTypes: <String, String>{
        for (final item in items.values)
          _normalize(item.href).toLowerCase(): item.mediaType,
      },
    );
  }

  int get chapterCount => spine.length;

  /// 读取正文 XHTML；缺失时返回 null。
  String? readChapter(int index) {
    if (index < 0 || index >= spine.length) return null;
    final file = _fileOf(_archive, spine[index].href);
    return file == null ? null : _decodeText(file);
  }

  /// 章节内相对资源（图片）→ 包内路径。
  String resolveInChapter(String chapterHref, String src) =>
      _resolve(chapterHref, _decode(src));

  /// 读取包内资源字节；缺失返回 null。
  Uint8List? readResource(String href) =>
      _fileOf(_archive, href)?.readBytes();

  /// 按 href 找 spine 下标；找不到返回 null。
  ///
  /// 目录里的 href 相对 OPF 目录（如 `text/ch1.xhtml`），spine 里的 href
  /// 是包内完整路径（如 `OEBPS/text/ch1.xhtml`），两种写法都要接受。
  int? spineIndexForHref(String href) {
    final decoded = _decode(href);
    final targets = <String>{
      _normalize(decoded).toLowerCase(),
      _resolve(opfPath, decoded).toLowerCase(),
    };
    for (var i = 0; i < spine.length; i++) {
      if (targets.contains(_normalize(spine[i].href).toLowerCase())) {
        return i;
      }
    }
    return null;
  }

  String mediaTypeOf(String href) =>
      _mediaTypes[_normalize(href).toLowerCase()] ?? '';

  static String _opfPathOf(Archive archive) {
    final container = _fileOf(archive, 'META-INF/container.xml');
    if (container == null) {
      throw const EpubInvalidException('EPUB 缺少 META-INF/container.xml');
    }
    try {
      final doc = XmlDocument.parse(
        _decodeText(container),
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
      final fullPath = _firstByLocal(doc, 'rootfile')?.getAttribute('full-path');
      if (fullPath == null || fullPath.trim().isEmpty) {
        throw const EpubInvalidException('EPUB 的 OPF 路径缺失');
      }
      return _normalize(fullPath);
    } on EpubInvalidException {
      rethrow;
    } catch (_) {
      throw const EpubInvalidException('EPUB 的 container.xml 已损坏');
    }
  }

  static XmlElement? _firstByLocal(XmlNode node, String localName) {
    for (final element in node.descendantElements) {
      if (element.name.local == localName) return element;
    }
    return null;
  }

  static String _resolve(String baseFile, String href) {
    if (href.isEmpty) return _normalize(baseFile);
    final dir = p.posix.dirname(baseFile);
    final joined = dir == '.' || dir.isEmpty ? href : p.posix.join(dir, href);
    return p.posix.normalize(joined);
  }

  static String _normalize(String path) {
    var value = path.replaceAll(r'\', '/');
    while (value.startsWith('./')) {
      value = value.substring(2);
    }
    while (value.startsWith('/')) {
      value = value.substring(1);
    }
    return p.posix.normalize(value);
  }

  static String _decode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  static ArchiveFile? _fileOf(Archive archive, String name) {
    final target = _normalize(name).toLowerCase();
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (_normalize(file.name).toLowerCase() == target) return file;
    }
    return null;
  }

  static String _decodeText(ArchiveFile file) {
    final bytes = file.readBytes();
    if (bytes == null) return '';
    return utf8.decode(bytes, allowMalformed: true);
  }
}

class _ManifestItem {
  const _ManifestItem({
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String href;
  final String mediaType;
  final String properties;

  bool get isNavigation => properties.split(' ').contains('nav');
}
