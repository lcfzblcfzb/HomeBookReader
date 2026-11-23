import 'package:flutter/material.dart';

/// 设置入口（本轮占位：数据说明与版本信息）。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: <Widget>[
          const ListTile(
            title: Text('数据存储'),
            subtitle: Text('所有 PDF、书签与笔记仅保存在本机应用私有目录，不上传、不联网。'),
          ),
          const Divider(height: 1),
          const ListTile(
            title: Text('版本'),
            subtitle: Text('0.1.0（M1 开发中）'),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '更多设置项将在后续里程碑开放。',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
