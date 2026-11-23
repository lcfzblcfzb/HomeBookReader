import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../application/reader_controller.dart';
import '../widgets/page_turn_layer.dart';
import 'reader_shell.dart';
import 'reader_ui_config.dart';

/// PDF 阅读模式：单页、点击左右区域翻页，公共外壳见 [ReaderShell]。
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late final ReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      documents: ref.read(documentRepositoryProvider),
      progress: ref.read(progressRepositoryProvider),
      bookmarks: ref.read(bookmarkRepositoryProvider),
      toc: ref.read(tocRepositoryProvider),
      documentId: widget.documentId,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReaderShell(session: _controller, bodyBuilder: _buildBody);
  }

  Widget _buildBody(BuildContext context) {
    return PageTurnLayer(
      onPrevious: _controller.previousPage,
      onNext: _controller.nextPage,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ratio = MediaQuery.devicePixelRatioOf(context);
          final pixelWidth = (constraints.maxWidth * ratio)
              .round()
              .clamp(320, 2400)
              .toInt();
          return _PageImage(
            controller: _controller,
            pageIndex: _controller.pageIndex,
            pixelWidth: pixelWidth,
          );
        },
      ),
    );
  }
}

class _PageImage extends StatefulWidget {
  const _PageImage({
    required this.controller,
    required this.pageIndex,
    required this.pixelWidth,
  });

  final ReaderController controller;
  final int pageIndex;
  final int pixelWidth;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  ui.Image? _image;
  bool _failed = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _PageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.pixelWidth != widget.pixelWidth) {
      unawaited(_load());
    }
  }

  /// 控制器持有渲染缓存并可能随时释放原图，这里克隆一份自己持有的句柄，
  /// 避免 `RawImage` 拿到已释放的 `ui.Image`（否则抛 Cannot clone a disposed image）。
  Future<void> _load() async {
    final requestId = ++_requestId;
    final source = await widget.controller.imageFor(
      widget.pageIndex,
      widget.pixelWidth,
    );
    if (!mounted || requestId != _requestId) return;
    ui.Image? cloned;
    if (source != null) {
      try {
        cloned = source.clone();
      } on StateError {
        cloned = null;
      }
    }
    setState(() {
      _image?.dispose();
      _image = cloned;
      _failed = cloned == null;
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      if (_failed) {
        return Center(
          child: Text(
            '这一页渲染失败',
            style: const TextStyle(color: ReaderUiConfig.readerForegroundColor),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return RawImage(image: image, fit: BoxFit.contain);
  }
}
