import 'package:flutter/material.dart';

import '../presentation/reader_ui_config.dart';

/// 入口素材：整张图等比显示 + 沿屏幕外法线方向的位移，不裁剪、不拉伸。
///
/// 素材在自己的坐标系里是横向的（132×40），外层用 `RotatedBox` 旋转 90°，
/// 让素材「顶端」朝向屏幕外侧（右侧贴边时为屏幕右边）。图片按 `BoxFit.contain`
/// 等比缩放，宽高比始终与源图一致；源图 96×96 时实际绘制 40×40 dp。
///
/// - [headReveal] = 0：整张图沿外法线推出 [ReaderUiConfig.entryStaticOutwardRatio]
///   个厚度，屏幕内只剩素材底部的一截（爪部），像爪子扒在边上；
/// - [headReveal] = 1：位移归零，整张图回到入口内，头部露出；
/// - [pullOffset]：拖拽时额外向外平移的像素，只改位移，不做任何形变。
///
/// 位移由 `Stack(clipBehavior: Clip.none)` 承载，允许素材部分超出可视区而不被
/// 意外裁掉；真正越出屏幕的部分由屏幕和入口形状自然裁掉。
class BookmarkEntryArtwork extends StatelessWidget {
  const BookmarkEntryArtwork({
    super.key,
    this.headReveal = 0,
    this.pullOffset = 0,
  });

  /// 头部露出进度：0 = 只露爪，1 = 完整可见。
  final double headReveal;

  /// 拖拽时额外向外平移的像素；不做缩放或拉伸。
  final double pullOffset;

  static const double _width = ReaderUiConfig.entryLength;
  static const double _height = ReaderUiConfig.entryThickness;

  @override
  Widget build(BuildContext context) {
    final outwardOffset =
        (1 - headReveal) *
            ReaderUiConfig.entryThickness *
            ReaderUiConfig.entryStaticOutwardRatio +
        pullOffset;
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Transform.translate(
            key: const ValueKey<String>('bookmark-entry-art-offset'),
            offset: Offset(0, -outwardOffset),
            // 等比缩放：按可用空间的最长边约束，宽高比与源图一致，不做非等比拉伸。
            child: Image.asset(
              ReaderUiConfig.entryAssetPath,
              width: _width,
              height: _height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Center(
                child: SizedBox.square(
                  dimension: _height,
                  child: const CustomPaint(
                    painter: _ArtworkPlaceholderPainter(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 资源缺失时的占位：整块圆角矩形，不做分层。
class _ArtworkPlaceholderPainter extends CustomPainter {
  const _ArtworkPlaceholderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(ReaderUiConfig.entryCornerRadius),
      ),
      Paint()..color = ReaderUiConfig.entryPlaceholderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtworkPlaceholderPainter oldDelegate) => false;
}
