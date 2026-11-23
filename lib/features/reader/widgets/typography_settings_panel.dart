import 'package:flutter/material.dart';

import '../../../core/ebook/epub_typography.dart';

/// EPUB 排版设置：字号 5 档、行距 2 档。
///
/// 刻意做成不依赖控制器的独立组件，方便以后从书签面板搬到别处。
class TypographySettingsPanel extends StatelessWidget {
  const TypographySettingsPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EpubTypography value;
  final ValueChanged<EpubTypography> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        Text('字号', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (var i = 0; i < EpubTypography.fontSizes.length; i++)
              ChoiceChip(
                label: Text(EpubTypography.fontLabels[i]),
                selected: value.fontLevel == i,
                onSelected: (_) => onChanged(value.copyWith(fontLevel: i)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('行距', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (var i = 0; i < EpubTypography.lineSpacings.length; i++)
              ChoiceChip(
                label: Text(EpubTypography.lineSpacingLabels[i]),
                selected: value.lineSpacingLevel == i,
                onSelected: (_) =>
                    onChanged(value.copyWith(lineSpacingLevel: i)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('页面边距', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(
          '左右 ${EpubTypography.horizontalMargin.toInt()} dp，上下 '
          '${EpubTypography.verticalMargin.toInt()} dp（固定）',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '春江潮水连海平，海上明月共潮生。\n'
            '滟滟随波千万里，何处春江无月明。',
            style: TextStyle(
              fontSize: value.fontSize,
              height: value.lineSpacing,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
