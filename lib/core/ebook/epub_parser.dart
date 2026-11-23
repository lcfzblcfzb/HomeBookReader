import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'epub_models.dart';

/// EPUB2 / EPUB3 解析：ZIP + mimetype 校验、OPF 元数据、封面、nav / ncx 目录。
///
/// 所有失败都以 [EpubInvalidException] 抛出，调用方转成中文导入提示，不允许崩溃。
abstract final class EpubParser {
  static const String _mimeType = 'application/epub+zip';

  /// ZIP 本地文件头 `PK\x03\x04` 的小端值。
  static const int _zipLocalHeader = 0x04034b50;

  /// 校验 ZIP 容器与 `mimetype` 条目；通过返回已解压归档。
  static Archive validate(List<int> bytes) {
    if (bytes.length < 4 || _readUint32(bytes, 0) != _zipLocalHeader) {
      throw const EpubInvalidException('不是有效的 EPUB（ZIP 容器校验失败）');
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const EpubInvalidException('EPUB 文件已损坏，无法解压');
    }
    final mime = _fileOf(archive, 'mimetype');
    if (mime == null) {
      throw const EpubInvalidException('不是有效的 EPUB（缺少 mimetype 条目）');
    }
    final content = _decodeText(mime).replaceAll('\uFEFF', '').trim();
    if (content != _mimeType) {
      throw const EpubInvalidException('不是有效的 EPUB（mimetype 内容不正确）');
    }
    return archive;
  }

  /// 解析元数据、封面与目录。校验不通过或结构损坏时抛 [EpubInvalidException]。
  static EpubBook parse(List<int> bytes) {
    final archive = validate(bytes);
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

    final metadata = _firstByLocal(opf, 'metadata');
    final manifest = _manifestItems(opf);
    final cover = _coverOf(archive, opfPath, metadata, manifest);
    return EpubBook(
      title: _firstText(metadata, 'title') ?? '',
      author: _firstText(metadata, 'creator'),
      coverBytes: cover?.bytes,
      coverExtension: cover?.extension,
      toc: _tocOf(archive, opfPath, opf, manifest),
    );
  }

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
      return _normalizePath(fullPath);
    } on EpubInvalidException {
      rethrow;
    } catch (_) {
      throw const EpubInvalidException('EPUB 的 container.xml 已损坏');
    }
  }

  /// 封面优先级：EPUB3 `cover-image` → EPUB2 `meta[name=cover]` → 文件名/id 含 cover 的图片。
  static _Cover? _coverOf(
    Archive archive,
    String opfPath,
    XmlElement? metadata,
    List<_ManifestItem> items,
  ) {
    _ManifestItem? cover;
    for (final item in items) {
      if (_hasProperty(item.properties, 'cover-image')) {
        cover = item;
        break;
      }
    }
    if (cover == null && metadata != null) {
      for (final meta in metadata.descendantElements.where(
        (e) => e.name.local == 'meta',
      )) {
        if (meta.getAttribute('name')?.toLowerCase() != 'cover') continue;
        final id = meta.getAttribute('content');
        for (final item in items) {
          if (item.id == id) {
            cover = item;
            break;
          }
        }
        if (cover != null) break;
      }
    }
    if (cover == null) {
      for (final item in items) {
        if (!item.mediaType.startsWith('image/')) continue;
        final lower = '${item.id} ${item.href}'.toLowerCase();
        if (lower.contains('cover')) {
          cover = item;
          break;
        }
      }
    }
    if (cover == null) return null;

    final path = _resolveRelative(opfPath, _decode(cover.href));
    final extension = _imageExtension(cover.mediaType, path);
    // 没有 SVG 解码器：直接回退占位，避免书架出现破图。
    if (extension == '.svg') return null;
    final bytes = _fileOf(archive, path)?.readBytes();
    if (bytes == null || bytes.isEmpty) return null;
    return _Cover(bytes, extension);
  }

  static List<EpubTocEntry> _tocOf(
    Archive archive,
    String opfPath,
    XmlDocument opf,
    List<_ManifestItem> items,
  ) {
    final nav = _tocFromNav(archive, opfPath, items);
    if (nav.isNotEmpty) return nav;
    return _tocFromNcx(archive, opfPath, opf, items);
  }

  /// EPUB3：manifest 中 `properties` 含 `nav` 的 XHTML。
  static List<EpubTocEntry> _tocFromNav(
    Archive archive,
    String opfPath,
    List<_ManifestItem> items,
  ) {
    _ManifestItem? nav;
    for (final item in items) {
      if (_hasProperty(item.properties, 'nav')) {
        nav = item;
        break;
      }
    }
    if (nav == null) return const <EpubTocEntry>[];

    final navFile = _fileOf(
      archive,
      _resolveRelative(opfPath, _decode(nav.href)),
    );
    if (navFile == null) return const <EpubTocEntry>[];
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(
        _decodeText(navFile),
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
    } catch (_) {
      return const <EpubTocEntry>[];
    }

    XmlElement? tocNav;
    for (final element in doc.descendantElements.where(
      (e) => e.name.local == 'nav',
    )) {
      final type =
          element.getAttribute('epub:type') ??
          element.getAttribute('type') ??
          '';
      if (type.toLowerCase().contains('toc')) {
        tocNav = element;
        break;
      }
      tocNav ??= element;
    }
    if (tocNav == null) return const <EpubTocEntry>[];

    final entries = <EpubTocEntry>[];
    for (final list in tocNav.descendantElements.where(
      (e) => e.name.local == 'ol',
    )) {
      _walkNavList(list, nav.href, 1, null, entries);
      break;
    }
    return entries;
  }

  static void _walkNavList(
    XmlElement list,
    String navHref,
    int level,
    int? parentIndex,
    List<EpubTocEntry> out,
  ) {
    for (final li in list.childElements.where((e) => e.name.local == 'li')) {
      XmlElement? anchor;
      for (final child in li.childElements) {
        if (child.name.local == 'a') {
          anchor = child;
          break;
        }
      }
      final title = anchor?.innerText.trim();
      final rawHref = anchor?.getAttribute('href');
      if (title == null || title.isEmpty || rawHref == null) continue;

      final target = _splitHref(navHref, rawHref);
      final index = out.length;
      out.add(
        EpubTocEntry(
          title: title,
          level: level,
          href: target.$1,
          fragment: target.$2,
          parentIndex: parentIndex,
        ),
      );
      for (final childList in li.childElements.where(
        (e) => e.name.local == 'ol',
      )) {
        _walkNavList(childList, navHref, level + 1, index, out);
      }
    }
  }

  /// EPUB2：spine 的 `toc` 属性指向的 NCX。
  static List<EpubTocEntry> _tocFromNcx(
    Archive archive,
    String opfPath,
    XmlDocument opf,
    List<_ManifestItem> items,
  ) {
    String? ncxId;
    for (final spine in opf.descendantElements.where(
      (e) => e.name.local == 'spine',
    )) {
      ncxId = spine.getAttribute('toc');
      if (ncxId != null) break;
    }
    _ManifestItem? ncx;
    for (final item in items) {
      if (item.id == ncxId) {
        ncx = item;
        break;
      }
    }
    if (ncx == null) {
      for (final item in items) {
        if (item.mediaType == 'application/x-dtbncx+xml') {
          ncx = item;
          break;
        }
      }
    }
    if (ncx == null) return const <EpubTocEntry>[];

    final ncxFile = _fileOf(
      archive,
      _resolveRelative(opfPath, _decode(ncx.href)),
    );
    if (ncxFile == null) return const <EpubTocEntry>[];
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(
        _decodeText(ncxFile),
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
    } catch (_) {
      return const <EpubTocEntry>[];
    }

    final navMap = _firstByLocal(doc, 'navMap');
    if (navMap == null) return const <EpubTocEntry>[];
    final entries = <EpubTocEntry>[];
    _walkNavPoints(navMap, ncx.href, 1, null, entries);
    return entries;
  }

  static void _walkNavPoints(
    XmlElement parent,
    String ncxHref,
    int level,
    int? parentIndex,
    List<EpubTocEntry> out,
  ) {
    for (final point in parent.childElements.where(
      (e) => e.name.local == 'navPoint',
    )) {
      final title = _firstText(point, 'text');
      String? src;
      for (final child in point.childElements) {
        if (child.name.local == 'content') {
          src = child.getAttribute('src');
          break;
        }
      }
      if (title == null || src == null || src.isEmpty) continue;

      final target = _splitHref(ncxHref, src);
      final index = out.length;
      out.add(
        EpubTocEntry(
          title: title,
          level: level,
          href: target.$1,
          fragment: target.$2,
          parentIndex: parentIndex,
        ),
      );
      _walkNavPoints(point, ncxHref, level + 1, index, out);
    }
  }

  static List<_ManifestItem> _manifestItems(XmlDocument opf) {
    final manifest = _firstByLocal(opf, 'manifest');
    if (manifest == null) return const <_ManifestItem>[];
    return manifest.childElements
        .where((e) => e.name.local == 'item')
        .map(
          (e) => _ManifestItem(
            id: e.getAttribute('id') ?? '',
            href: e.getAttribute('href') ?? '',
            mediaType: e.getAttribute('media-type') ?? '',
            properties: e.getAttribute('properties') ?? '',
          ),
        )
        .where((item) => item.href.isNotEmpty)
        .toList();
  }

  static bool _hasProperty(String properties, String name) =>
      properties.split(RegExp(r'\s+')).contains(name);

  static String? _firstText(XmlNode? parent, String localName) {
    if (parent == null) return null;
    for (final element in parent.descendantElements) {
      if (element.name.local != localName) continue;
      final text = element.innerText.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static XmlElement? _firstByLocal(XmlNode node, String localName) {
    for (final element in node.descendantElements) {
      if (element.name.local == localName) return element;
    }
    return null;
  }

  /// `href` → `(相对 OPF 目录的路径, 片段)`。
  static (String, String?) _splitHref(String baseFile, String raw) {
    final hash = raw.indexOf('#');
    final pathPart = hash >= 0 ? raw.substring(0, hash) : raw;
    final fragment = hash >= 0 ? _decode(raw.substring(hash + 1)) : '';
    final decodedPath = _decode(pathPart);
    final href = decodedPath.isEmpty
        ? _normalizePath(baseFile)
        : _resolveRelative(baseFile, decodedPath);
    return (href, fragment.isEmpty ? null : fragment);
  }

  static String _resolveRelative(String baseFile, String href) {
    final dir = p.posix.dirname(baseFile);
    final joined = dir == '.' || dir.isEmpty
        ? href
        : p.posix.join(dir, href);
    return p.posix.normalize(joined);
  }

  static String _normalizePath(String path) {
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

  static String _imageExtension(String mediaType, String path) {
    switch (mediaType.toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/svg+xml':
        return '.svg';
    }
    return switch (p.posix.extension(path).toLowerCase()) {
      '.jpg' || '.jpeg' => '.jpg',
      '.png' => '.png',
      '.gif' => '.gif',
      '.webp' => '.webp',
      '.svg' => '.svg',
      _ => '.img',
    };
  }

  static ArchiveFile? _fileOf(Archive archive, String name) {
    final target = _normalizePath(name).toLowerCase();
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (_normalizePath(file.name).toLowerCase() == target) return file;
    }
    return null;
  }

  static String _decodeText(ArchiveFile file) {
    final bytes = file.readBytes();
    if (bytes == null) return '';
    return utf8.decode(bytes, allowMalformed: true);
  }

  static int _readUint32(List<int> bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String href;
  final String mediaType;
  final String properties;
}

class _Cover {
  const _Cover(this.bytes, this.extension);

  final Uint8List bytes;
  final String extension;
}
