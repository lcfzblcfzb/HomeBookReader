import 'dart:typed_data';

/// EPUB 校验/解析失败。`reason` 为可直接展示的中文原因。
class EpubInvalidException implements Exception {
  const EpubInvalidException(this.reason);

  final String reason;

  @override
  String toString() => 'EpubInvalidException($reason)';
}

/// EPUB 扁平化后的一条目录项。
///
/// EPUB 没有页概念，定位由 [href]（相对 OPF 目录、已 URL 解码）与
/// [fragment]（`#` 之后，可空）表达；[parentIndex] 指向扁平列表中的父项。
class EpubTocEntry {
  const EpubTocEntry({
    required this.title,
    required this.level,
    required this.href,
    this.fragment,
    this.parentIndex,
  });

  final String title;

  /// 1 基层级，与 `toc_entries.level` 一致。
  final int level;
  final String href;
  final String? fragment;
  final int? parentIndex;
}

/// 解析出的 EPUB 元数据。
class EpubBook {
  const EpubBook({
    required this.title,
    this.author,
    this.coverBytes,
    this.coverExtension,
    this.toc = const <EpubTocEntry>[],
  });

  final String title;
  final String? author;

  /// 封面原图字节；缺失或格式不受支持时为 null。
  final Uint8List? coverBytes;

  /// 封面文件扩展名（含点，如 `.jpg`）。
  final String? coverExtension;
  final List<EpubTocEntry> toc;
}
