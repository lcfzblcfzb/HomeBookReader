import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/ebook/book_format.dart';
import '../../../data/db/app_database.dart';
import 'epub_reader_page.dart';
import 'reader_page.dart';
import 'reader_ui_config.dart';

/// 阅读入口：先确认文档格式，再交给 PDF 或 EPUB 阅读页。
class ReaderHostPage extends ConsumerStatefulWidget {
  const ReaderHostPage({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<ReaderHostPage> createState() => _ReaderHostPageState();
}

class _ReaderHostPageState extends ConsumerState<ReaderHostPage> {
  late final Future<DocumentRow?> _document;

  @override
  void initState() {
    super.initState();
    _document = ref.read(documentRepositoryProvider).byId(widget.documentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentRow?>(
      future: _document,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: ReaderUiConfig.readerBackgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final document = snapshot.data;
        if (document == null) {
          return Scaffold(
            backgroundColor: ReaderUiConfig.readerBackgroundColor,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    '文档不存在，可能已被删除',
                    style: TextStyle(
                      color: ReaderUiConfig.readerForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () => context.go('/'),
                    child: const Text('返回书架'),
                  ),
                ],
              ),
            ),
          );
        }
        if (document.format == BookFormat.epub.name) {
          return EpubReaderPage(documentId: widget.documentId);
        }
        return ReaderPage(documentId: widget.documentId);
      },
    );
  }
}
