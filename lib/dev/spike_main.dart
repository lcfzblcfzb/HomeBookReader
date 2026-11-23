import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import '../core/pdf/pdf_models.dart';
import '../core/pdf/pdfrx_engine.dart';
import '../core/storage/app_paths.dart';
import '../data/db/app_database.dart';

/// M0 技术验证入口（不参与正式发布）：
/// flutter run -d windows -t lib/dev/spike_main.dart --dart-define=SPIKE_DIR=<样本目录>
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpikeApp());
}

class SpikeApp extends StatefulWidget {
  const SpikeApp({super.key});

  @override
  State<SpikeApp> createState() => _SpikeAppState();
}

class _SpikeAppState extends State<SpikeApp> {
  final List<String> _lines = <String>[];
  bool _done = false;

  static const String _assetsDir = String.fromEnvironment('SPIKE_DIR', defaultValue: 'test_assets');

  @override
  void initState() {
    super.initState();
    _run();
  }

  void _log(String line) {
    debugPrint('[SPIKE] $line');
    if (mounted) setState(() => _lines.add(line));
  }

  Future<void> _run() async {
    await AppPaths.init();
    final dir = Directory(_assetsDir);
    _log('样本目录：${dir.absolute.path}（存在=${dir.existsSync()}）');
    try {
      await _spikeTextAndOutline(dir);
      await _spikeRenderAndMemory(dir);
      await _spikeDatabase();
    } catch (e, st) {
      _log('SPIKE 异常：$e');
      _log(st.toString());
    }
    _log('==== 验证结束 ====');
    _done = true;
    if (mounted) setState(() {});
  }

  Future<void> _spikeTextAndOutline(Directory dir) async {
    final engine = const PdfrxEngine();
    _log('--- S2/S3 文本与目录 ---');
    for (final name in <String>['sample_text_zh.pdf', 'sample_text_en.pdf', 'sample_no_outline.pdf', 'sample_scanned.pdf']) {
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      if (!file.existsSync()) {
        _log('$name 缺失，跳过');
        continue;
      }
      final sw = Stopwatch()..start();
      final handle = await engine.open(file.path);
      final openMs = sw.elapsedMilliseconds;
      final hasText = await handle.hasTextLayer();
      final size = await handle.pageSize(0);
      final lines = hasText ? await handle.textLines(0) : const <PdfTextLine>[];
      final charRectCount = lines.fold<int>(0, (sum, line) => sum + line.charRects.length);
      final outline = await handle.outline();
      final outlineInfo = _outlineSummary(outline);
      _log(
        '$name: 页数=${handle.pageCount} 打开=${openMs}ms 页尺寸=${size.width.toStringAsFixed(1)}x'
        '${size.height.toStringAsFixed(1)} 文字层=$hasText 首行数=${lines.length} 字符矩形=$charRectCount',
      );
      if (lines.isNotEmpty) {
        final first = lines.first;
        _log('  首行文本="${first.text}" bounds=${first.bounds} charRects=${first.charRects.length}');
        _log('  末行文本="${lines.last.text}"');
      }
      _log('  outline: $outlineInfo');
      await handle.dispose();
    }
  }

  String _outlineSummary(List<PdfOutlineNode> nodes) {
    if (nodes.isEmpty) return '空（无目录）';
    var count = 0;
    var maxLevel = 0;
    final samples = <String>[];
    void walk(List<PdfOutlineNode> items) {
      for (final node in items) {
        count++;
        maxLevel = max(maxLevel, node.level);
        if (samples.length < 3) samples.add('${node.title}(L${node.level} p${node.pageIndex})');
        walk(node.children);
      }
    }

    walk(nodes);
    return '节点=$count 最大层级=$maxLevel 示例=$samples';
  }

  Future<void> _spikeRenderAndMemory(Directory dir) async {
    _log('--- S1 渲染与内存 ---');
    final file = File('${dir.path}${Platform.pathSeparator}sample_text_zh.pdf');
    if (!file.existsSync()) {
      _log('sample_text_zh.pdf 缺失，跳过');
      return;
    }
    final engine = const PdfrxEngine();
    final handle = await engine.open(file.path);
    for (final width in <int>[800, 1600]) {
      final sw = Stopwatch()..start();
      final image = await handle.renderPage(0, pixelWidth: width);
      final ms = sw.elapsedMilliseconds;
      _log('渲染 ${width}px: ${ms}ms -> ${image.width}x${image.height}');
      image.dispose();
    }
    final sw = Stopwatch()..start();
    final second = await handle.renderPage(1, pixelWidth: 1200);
    _log('渲染第 2 页 1200px: ${sw.elapsedMilliseconds}ms -> ${second.width}x${second.height}');
    second.dispose();
    await handle.dispose();
    _log('常驻内存 RSS=${(ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(1)}MB');
  }

  Future<void> _spikeDatabase() async {
    _log('--- S4 SQLite 基线 ---');
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        await db.documentsDao.insertDocument(
          DocumentsCompanion.insert(
            id: 'doc-$i',
            sha256: 'hash-$i',
            title: '文档 $i',
            relPath: 'pdfs/doc-$i.pdf',
            pageCount: const Value(100),
            fileSize: 1024,
            hasTextLayer: true,
            addedAt: i,
          ),
        );
      }
      final insertMs = sw.elapsedMilliseconds;

      final query = Stopwatch()..start();
      final all = await db.documentsDao.listAll();
      final queryMs = query.elapsedMilliseconds;

      final del = Stopwatch()..start();
      await db.documentsDao.deleteById('doc-0');
      await db.progressDao.upsert(
        ReadingProgressCompanion.insert(documentId: 'doc-1', pageIndex: const Value(3), updatedAt: 1, offsetY: const Value(0.5)),
      );
      final cascadeMs = del.elapsedMilliseconds;
      _log('插入 1000 条=${insertMs}ms 查询全部=${queryMs}ms（${all.length} 行）写入/删除=${cascadeMs}ms');
      final progress = await db.progressDao.byDocument('doc-1');
      _log('进度读写：pageIndex=${progress?.pageIndex}');
    } finally {
      await db.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text(_done ? 'M0 Spike 完成' : 'M0 Spike 运行中')),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _lines.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(_lines[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
      ),
    );
  }
}
