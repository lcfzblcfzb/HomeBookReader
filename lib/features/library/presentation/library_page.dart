import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/db/app_database.dart';
import '../application/library_controller.dart';
import '../widgets/book_tile.dart';

/// 书架模式：浏览已导入 PDF、导入新文件、进入设置。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final LibraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LibraryController(
      documents: ref.read(documentRepositoryProvider),
      progress: ref.read(progressRepositoryProvider),
    );
    // 上次导入若在文件选择器打开期间被系统打断，这里把结果取回来接着导入。
    unawaited(_recoverLostImport());
  }

  Future<void> _recoverLostImport() async {
    final report = await _controller.recoverLostImport();
    if (!mounted || report == null) return;
    final message = _messageOf(report);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showImportSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('选择 PDF / EPUB 文件'),
              subtitle: const Text('从系统文件选择器导入'),
              onTap: () => Navigator.of(context).pop('picker'),
            ),
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: const Text('扫描本机文件'),
              subtitle: const Text('遍历本机存储，批量选择导入'),
              onTap: () => Navigator.of(context).pop('scan'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'scan') {
      await context.push('/scan');
      return;
    }
    await _handleImport();
  }

  Future<void> _handleImport() async {
    final report = await _controller.pickAndImport();
    if (!mounted || report.cancelled) return;
    final message = _messageOf(report);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (report.imported.isEmpty && report.duplicates.isNotEmpty) {
      await _openDocument(report.duplicates.first);
    }
  }

  Future<void> _openDocument(DocumentRow document) async {
    await context.push('/reader/${document.id}');
  }

  String? _messageOf(ImportReport report) {
    if (!report.hasAnything) return null;
    final parts = <String>[
      if (report.imported.isNotEmpty) '成功导入 ${report.imported.length} 本',
      if (report.duplicates.isNotEmpty) '${report.duplicates.length} 本已在书架',
      if (report.failures.isNotEmpty) '${report.failures.length} 个文件失败',
    ];
    final detail = report.failures.isEmpty ? '' : '\n${report.failures.first}';
    return '${parts.join('，')}$detail';
  }

  Future<void> _confirmDelete(DocumentRow document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文档'),
        content: Text('将删除《${document.title}》及其书签、标注与阅读进度，且不可恢复。'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.delete(document.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: <Widget>[
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) => IconButton(
              tooltip: '导入文件',
              onPressed: _controller.importing ? null : _showImportSheet,
              icon: _controller.importing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
            ),
          ),
          IconButton(
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _controller.errorMessage;
          if (error != null) {
            return Center(child: Text(error));
          }
          if (_controller.items.isEmpty) {
            return _EmptyLibrary(onImport: _showImportSheet);
          }
          return ListView.separated(
            itemCount: _controller.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final document = _controller.items[index];
              return BookTile(
                document: document,
                position: _controller.positionOf(document.id),
                onTap: () => _openDocument(document),
                onDelete: () => _confirmDelete(document),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_stories_outlined, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('书架还是空的', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('导入本地 PDF / EPUB 开始阅读', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => onImport(),
            child: const Text('导入文件'),
          ),
        ],
      ),
    );
  }
}
