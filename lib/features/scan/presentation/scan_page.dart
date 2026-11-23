import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../application/book_scan_service.dart';
import '../application/scan_controller.dart';

/// 扫描本机文件（PDF / EPUB）：权限门、扫描进度、结果多选导入。
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final ScanController _controller;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _controller = ScanController(documents: ref.read(documentRepositoryProvider));
    _lifecycle = AppLifecycleListener(onResume: _maybeResumeScan);
    unawaited(_startIfAllowed());
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startIfAllowed() async {
    await _controller.prepare();
    if (!mounted) return;
    if (!_controller.needsPermission &&
        !_controller.scanning &&
        _controller.results.isEmpty) {
      await _controller.startScan();
    }
  }

  Future<void> _maybeResumeScan() async {
    await _controller.refreshAccess();
    if (!mounted) return;
    if (!_controller.needsPermission &&
        !_controller.scanning &&
        _controller.results.isEmpty &&
        !_controller.cancelled) {
      await _controller.startScan();
    }
  }

  Future<void> _importSelected() async {
    final summary = await _controller.importSelected();
    if (!mounted || !summary.hasAnything) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(summary.message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描本机文件'),
        actions: <Widget>[
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              if (_controller.scanning) {
                return TextButton(
                  onPressed: _controller.cancelScan,
                  child: const Text('取消扫描'),
                );
              }
              return IconButton(
                tooltip: '重新扫描',
                onPressed: _controller.needsPermission
                    ? null
                    : () => unawaited(_controller.startScan()),
                icon: const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => _buildBody(context),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.results.isEmpty) return const SizedBox.shrink();
          return SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Text('已选 ${_controller.selected.length} / ${_controller.results.length}'),
                  const Spacer(),
                  FilledButton(
                    onPressed: _controller.selected.isEmpty || _controller.importing
                        ? null
                        : () => unawaited(_importSelected()),
                    child: _controller.importing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('导入选中'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    if (_controller.checkingAccess) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.needsPermission) {
      return _PermissionCard(
        onRequest: () => unawaited(_controller.requestAccess()),
        onRecheck: () => unawaited(_controller.refreshAccess()),
      );
    }
    if (_controller.scanning) {
      return _ScanningView(
        visited: _controller.visited,
        found: _controller.found,
        onCancel: _controller.cancelScan,
      );
    }
    final error = _controller.errorMessage;
    if (error != null && _controller.results.isEmpty) {
      return _CenterHint(
        icon: Icons.error_outline,
        title: error,
        actionLabel: '重新扫描',
        onAction: () => unawaited(_controller.startScan()),
      );
    }
    if (_controller.cancelled && _controller.results.isEmpty) {
      return _CenterHint(
        icon: Icons.search_off,
        title: '扫描已取消',
        actionLabel: '重新扫描',
        onAction: () => unawaited(_controller.startScan()),
      );
    }
    if (_controller.results.isEmpty) {
      return _CenterHint(
        icon: Icons.search_off,
        title: '没有找到 PDF 或 EPUB 文件',
        subtitle: '已扫描 ${_controller.visited} 个文件。换个位置或确认存储权限后再试。',
        actionLabel: '重新扫描',
        onAction: () => unawaited(_controller.startScan()),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '发现 ${_controller.results.length} 个文件',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: _controller.selectAll,
                child: const Text('全选'),
              ),
              TextButton(
                onPressed: _controller.clearSelection,
                child: const Text('清空'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _controller.results.length,
            itemBuilder: (context, index) {
              final file = _controller.results[index];
              final selected = _controller.isSelected(file.path);
              final tag = _tagOf(file);
              return CheckboxListTile(
                value: selected,
                onChanged: (_) => _controller.toggleSelected(file.path),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      file.directory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          formatBytes(file.sizeBytes),
                          style: theme.textTheme.labelSmall,
                        ),
                        if (tag != null) ...<Widget>[
                          const SizedBox(width: 8),
                          _Tag(label: tag.$1, warning: tag.$2),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 优先级：导入失败原因 > 可疑文件 > 已在书架。
  (String, bool)? _tagOf(ScannedBook file) {
    final issue = _controller.issueOf(file);
    if (issue != null) {
      if (issue.contains('加密')) return ('已加密', true);
      return ('无法导入', true);
    }
    if (file.looksBroken) return ('可能损坏', true);
    if (_controller.inLibrary(file)) return ('已在书架', false);
    return null;
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onRequest, required this.onRecheck});

  final VoidCallback onRequest;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Icon(Icons.folder_shared_outlined, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text('扫描需要读取本机文件', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Android 11 及以上：需要在系统设置里开启「所有文件访问权限」，返回后会自动继续扫描。\n'
          'Android 10 及以下：会弹出存储读取权限，选择允许即可。\n'
          '文件只在本机遍历，不会上传。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onRequest,
          child: const Text('去授权'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRecheck,
          child: const Text('已授权，重新检查'),
        ),
      ],
    );
  }
}

class _ScanningView extends StatelessWidget {
  const _ScanningView({
    required this.visited,
    required this.found,
    required this.onCancel,
  });

  final int visited;
  final int found;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text('正在扫描…', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '已扫描 $visited 个文件，发现 $found 个 PDF / EPUB',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onCancel, child: const Text('取消扫描')),
          ],
        ),
      ),
    );
  }
}

class _CenterHint extends StatelessWidget {
  const _CenterHint({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(subtitle!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.warning});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = warning ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
