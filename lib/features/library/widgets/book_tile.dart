import 'package:flutter/material.dart';

import '../../../core/ebook/book_format.dart';
import '../../../core/storage/app_paths.dart';
import '../../../data/db/app_database.dart';

/// 书架条目：封面 + 标题 + 页数。
class BookTile extends StatelessWidget {
  const BookTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
    this.position,
  });

  final DocumentRow document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// EPUB 阅读位置（0–1）；未读过或 PDF 为 null。
  final double? position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEpub = document.format == BookFormat.epub.name;
    final author = document.author?.trim();
    final percent = ((position ?? 0).clamp(0.0, 1.0) * 100).round();
    final subtitle = isEpub
        // EPUB 没有页概念，进度用「位置」百分比表示。
        ? '${author == null || author.isEmpty ? '未知作者' : author} · 位置 $percent%'
        : '${document.pageCount ?? 0} 页${document.hasTextLayer ? '' : ' · 无文字层'}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      onLongPress: onDelete,
      leading: _Cover(relPath: document.coverRelPath, isEpub: isEpub),
      title: Text(
        document.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        tooltip: '删除',
        icon: const Icon(Icons.more_horiz),
        onPressed: onDelete,
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.relPath, required this.isEpub});

  final String? relPath;
  final bool isEpub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: 44,
      height: 58,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        isEpub ? Icons.menu_book_outlined : Icons.picture_as_pdf_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final path = relPath;
    if (path == null) return placeholder;
    final file = AppPaths.resolve(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 44,
        height: 58,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 132,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}
