import 'package:flutter/foundation.dart';

/// EPUB 分页排版的字号 / 行距 / 页边距。
///
/// 字号 5 档、行距 2 档、页边距一档默认值；标题、段距、缩进都由字号推导，
/// 改档位会触发整本重排。这里只放纯数值，方便分页引擎与设置面板共用。
@immutable
class EpubTypography {
  const EpubTypography({this.fontLevel = 2, this.lineSpacingLevel = 0});

  /// 字号档位（0–4）。
  final int fontLevel;

  /// 行距档位（0 标准 / 1 宽松）。
  final int lineSpacingLevel;

  static const List<double> fontSizes = <double>[14, 16, 18, 20, 22];
  static const List<double> lineSpacings = <double>[1.5, 1.8];
  static const List<String> fontLabels = <String>['小', '较小', '标准', '较大', '大'];
  static const List<String> lineSpacingLabels = <String>['标准', '宽松'];

  /// 页面左侧与右侧的留白（dp）。
  static const double horizontalMargin = 24;

  /// 页面顶部与底部的留白（dp），会再叠加系统安全区。
  static const double verticalMargin = 28;

  double get fontSize => fontSizes[fontLevel];

  /// 行高倍数。
  double get lineSpacing => lineSpacings[lineSpacingLevel];

  /// 正文单行高度（dp）。
  double get lineHeight => fontSize * lineSpacing;

  /// 标题字号倍数。
  double headingScale(int level) => switch (level) {
    1 => 1.6,
    2 => 1.4,
    3 => 1.22,
    4 => 1.12,
    _ => 1.0,
  };

  EpubTypography copyWith({int? fontLevel, int? lineSpacingLevel}) =>
      EpubTypography(
        fontLevel: fontLevel ?? this.fontLevel,
        lineSpacingLevel: lineSpacingLevel ?? this.lineSpacingLevel,
      );

  @override
  bool operator ==(Object other) =>
      other is EpubTypography &&
      other.fontLevel == fontLevel &&
      other.lineSpacingLevel == lineSpacingLevel;

  @override
  int get hashCode => Object.hash(fontLevel, lineSpacingLevel);

  @override
  String toString() =>
      'EpubTypography(font: $fontSize, line: $lineSpacing)';
}
