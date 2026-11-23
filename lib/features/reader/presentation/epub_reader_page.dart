import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/ebook/epub_typography.dart';
import '../application/epub_paginator.dart';
import '../application/epub_reader_controller.dart';
import '../widgets/page_turn_layer.dart';
import '../widgets/typography_settings_panel.dart';
import 'reader_shell.dart';
import 'reader_ui_config.dart';

/// EPUB 分页阅读页：正文按当前字号 / 行距 / 可用宽高切页。
class EpubReaderPage extends ConsumerStatefulWidget {
  const EpubReaderPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends ConsumerState<EpubReaderPage> {
  late final EpubReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EpubReaderController(
      documents: ref.read(documentRepositoryProvider),
      progress: ref.read(progressRepositoryProvider),
      bookmarks: ref.read(bookmarkRepositoryProvider),
      toc: ref.read(tocRepositoryProvider),
      typography: ref.read(readerTypographyRepositoryProvider),
      documentId: widget.documentId,
    );
    unawaited(_controller.open());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReaderShell(
      session: _controller,
      bodyBuilder: _buildBody,
      typographyBuilder: (context, session) {
        if (session is! EpubReaderController) return const SizedBox.shrink();
        return TypographySettingsPanel(
          value: session.typography,
          onChanged: (value) => unawaited(session.setTypography(value)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    return PageTurnLayer(
      onPrevious: _controller.previousPage,
      onNext: _controller.nextPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final view = media.viewPadding;
          const margin = EpubTypography.horizontalMargin;
          const vertical = EpubTypography.verticalMargin;
          final width = (constraints.maxWidth -
                  view.left -
                  view.right -
                  margin * 2)
              .clamp(120.0, double.infinity);
          final height = (constraints.maxHeight -
                  view.top -
                  view.bottom -
                  vertical * 2)
              .clamp(120.0, double.infinity);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _controller.setViewport(Size(width, height));
          });
          return Padding(
            padding: EdgeInsets.fromLTRB(
              view.left + margin,
              view.top + vertical,
              view.right + margin,
              view.bottom + vertical,
            ),
            child: _EpubPageView(controller: _controller),
          );
        },
      ),
    );
  }
}

/// 当前页渲染；排版未完成时显示轻量加载态。
class _EpubPageView extends StatelessWidget {
  const _EpubPageView({required this.controller});

  final EpubReaderController controller;

  @override
  Widget build(BuildContext context) {
    final error = controller.chapterError;
    if (error != null) {
      return Center(
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: ReaderUiConfig.readerForegroundColor),
        ),
      );
    }
    final page = controller.currentPage;
    if (page == null) {
      if (!controller.layouting) {
        return const Center(
          child: Text(
            '本章暂无内容',
            style: TextStyle(color: ReaderUiConfig.readerForegroundColor),
          ),
        );
      }
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    // 按排版结果绝对定位，保证与分页测量一致；超出一页的部分由 ClipRect 裁掉。
    final children = <Widget>[];
    var top = 0.0;
    for (final item in page.items) {
      top += item.spacingBefore;
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: top,
          height: item.height,
          child: _buildItem(item),
        ),
      );
      top += item.height;
    }
    return ClipRect(
      child: Stack(clipBehavior: Clip.hardEdge, children: children),
    );
  }

  Widget _buildItem(EpubPageItem item) {
    switch (item) {
      case final EpubTextItem text:
        final style = EpubBlockStyle.of(text.block.kind, controller.typography);
        return Text.rich(
          TextSpan(
            style: style.textStyle,
            children: <InlineSpan>[
              for (final run in text.runs)
                TextSpan(text: run.text, style: style.runStyle(run)),
            ],
          ),
          strutStyle: StrutStyle(
            fontSize: style.fontSize,
            height: controller.typography.lineSpacing,
            forceStrutHeight: true,
            leading: 0,
          ),
          textAlign: TextAlign.left,
          textWidthBasis: TextWidthBasis.parent,
          // 与分页测量保持一致，避免系统字体缩放导致溢出。
          textScaler: TextScaler.noScaling,
        );
      case final EpubImageItem image:
        return Center(child: _buildImage(image));
      case EpubDividerItem():
        return Divider(
          height: 1,
          thickness: 1,
          color: ReaderUiConfig.epubDividerColor,
        );
    }
  }

  Widget _buildImage(EpubImageItem image) {
    final Uint8List? bytes = controller.imageBytes(image.href);
    if (bytes == null) {
      return Text(
        image.alt ?? '图片无法显示',
        style: const TextStyle(color: ReaderUiConfig.epubQuoteColor),
      );
    }
    return Image.memory(
      bytes,
      width: image.width,
      height: image.height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => Text(
        image.alt ?? '图片无法显示',
        style: const TextStyle(color: ReaderUiConfig.epubQuoteColor),
      ),
    );
  }
}
