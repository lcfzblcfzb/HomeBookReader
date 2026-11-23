import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';
import '../../reader/application/reader_session.dart';
import '../../reader/presentation/reader_ui_config.dart';
import '../../toc/presentation/toc_list.dart';

/// 书签模式：从屏幕右侧横向滑入的面板，遮罩与滑入动画由阅读页统一驱动。
///
/// 面板内用页签承载「书签 / 目录」，EPUB 再追加「排版」（由阅读页注入）。
class BookmarkPanel extends StatelessWidget {
  const BookmarkPanel({
    super.key,
    required this.tab,
    required this.onTabChanged,
    required this.bookmarks,
    required this.onClose,
    required this.onGoToBookshelf,
    required this.onAdd,
    required this.onJump,
    required this.onDelete,
    required this.bookmarkLocation,
    required this.tocEntries,
    required this.tocLoading,
    required this.tocError,
    required this.hasTextLayer,
    required this.onJumpEntry,
    required this.isCurrentEntry,
    required this.tocEntryLocation,
    this.typographyPanel,
  });

  final ReaderPanelTab tab;
  final ValueChanged<ReaderPanelTab> onTabChanged;
  final List<BookmarkRow> bookmarks;
  final VoidCallback onClose;

  /// 返回书架：Windows 没有系统返回键，面板里给一个显式入口。
  final VoidCallback onGoToBookshelf;
  final VoidCallback onAdd;
  final ValueChanged<BookmarkRow> onJump;
  final ValueChanged<BookmarkRow> onDelete;
  final String Function(BookmarkRow bookmark) bookmarkLocation;
  final List<TocEntryRow> tocEntries;
  final bool tocLoading;
  final String? tocError;
  final bool hasTextLayer;
  final ValueChanged<TocEntryRow> onJumpEntry;
  final bool Function(TocEntryRow entry) isCurrentEntry;
  final String Function(TocEntryRow entry) tocEntryLocation;

  /// EPUB 的「排版」页签内容；为 null 时不显示该页签。
  final Widget? typographyPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showTypography = typographyPanel != null;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(ReaderUiConfig.panelCornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: true,
        bottom: true,
        left: true,
        right: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _PanelTabButton(
                            label: '书签',
                            selected: tab == ReaderPanelTab.bookmarks,
                            onTap: () =>
                                onTabChanged(ReaderPanelTab.bookmarks),
                          ),
                          _PanelTabButton(
                            label: '目录',
                            selected: tab == ReaderPanelTab.toc,
                            onTap: () => onTabChanged(ReaderPanelTab.toc),
                          ),
                          if (showTypography)
                            _PanelTabButton(
                              label: '排版',
                              selected: tab == ReaderPanelTab.typography,
                              onTap: () =>
                                  onTabChanged(ReaderPanelTab.typography),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (tab == ReaderPanelTab.bookmarks)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(showTypography ? '当前位置' : '当前页'),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: onGoToBookshelf,
                    icon: const Icon(Icons.library_books, size: 18),
                    label: const Text('书架'),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _buildTabBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(ThemeData theme) => switch (tab) {
    ReaderPanelTab.bookmarks => _buildBookmarks(theme),
    ReaderPanelTab.toc => _buildToc(theme),
    ReaderPanelTab.typography => typographyPanel ?? const SizedBox.shrink(),
  };

  Widget _buildBookmarks(ThemeData theme) {
    if (bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Text(
          '还没有书签。点击「${typographyPanel != null ? '当前位置' : '当前页'}」把这一处记下来。',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.bookmark_outline, size: 20),
          title: Text(bookmark.label),
          subtitle: Text(bookmarkLocation(bookmark)),
          onTap: () => onJump(bookmark),
          trailing: IconButton(
            tooltip: '删除书签',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => onDelete(bookmark),
          ),
        );
      },
    );
  }

  Widget _buildToc(ThemeData theme) {
    if (tocLoading && tocEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (tocEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Text(
          tocError ??
              (hasTextLayer ? '该文档未提供目录。' : '该文档是扫描件，没有可用的目录。'),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    return TocList(
      entries: tocEntries,
      isCurrentEntry: isCurrentEntry,
      locationLabel: tocEntryLocation,
      onJumpEntry: onJumpEntry,
    );
  }
}

/// 面板内的轻量页签：选中态用主题色 + 下划线，不引额外控件。
class _PanelTabButton extends StatelessWidget {
  const _PanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: selected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
