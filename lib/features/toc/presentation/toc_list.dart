import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';

/// 阅读面板「目录」页签的列表：按层级缩进、当前章节高亮、点击跳转。
///
/// PDF 与 EPUB 共用；页码文字由 [locationLabel] 提供，EPUB 返回空串时隐藏。
class TocList extends StatelessWidget {
  const TocList({
    super.key,
    required this.entries,
    required this.isCurrentEntry,
    required this.locationLabel,
    required this.onJumpEntry,
  });

  final List<TocEntryRow> entries;
  final bool Function(TocEntryRow entry) isCurrentEntry;
  final String Function(TocEntryRow entry) locationLabel;
  final ValueChanged<TocEntryRow> onJumpEntry;

  static const double _baseIndent = 20;
  static const double _indentStep = 16;
  static const int _maxIndentLevel = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 固定行高 + 显式高度，保证长目录只构建可见项（面板高度仍随条目数收缩）。
    final rowHeight = MediaQuery.textScalerOf(context).scale(20) + 20;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(
          entries.length * rowHeight + 16,
          constraints.maxHeight,
        );
        return SizedBox(
          height: height,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            itemExtent: rowHeight,
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final current = isCurrentEntry(entry);
              final jumpable =
                  (entry.pageIndex != null && entry.pageIndex! >= 0) ||
                  (entry.href != null && entry.href!.isNotEmpty);
              final location = locationLabel(entry);
              final depth = (entry.level - 1).clamp(0, _maxIndentLevel);
              return InkWell(
                onTap: jumpable ? () => onJumpEntry(entry) : null,
                child: Container(
                  color: current
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                      : null,
                  padding: EdgeInsets.fromLTRB(
                    _baseIndent + depth * _indentStep,
                    0,
                    16,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 3,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: current
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: current
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: jumpable
                                ? (current
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (location.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 8),
                        Text(
                          location,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: current
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
