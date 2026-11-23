import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../../core/ebook/book_format.dart';

/// 扫描到的一个文件（PDF / EPUB）。
class ScannedBook {
  const ScannedBook({
    required this.path,
    required this.name,
    required this.directory,
    required this.sizeBytes,
    required this.format,
    required this.hasValidHeader,
  });

  final String path;
  final String name;
  final String directory;
  final int sizeBytes;
  final BookFormat format;

  /// PDF 的 `%PDF-` / EPUB 的 `PK\x03\x04` 文件头校验。
  /// EPUB 的完整 mimetype 校验留给导入阶段，避免扫描时解压大量文件。
  final bool hasValidHeader;

  bool get looksBroken => !hasValidHeader;
}

class ScanProgress {
  const ScanProgress({required this.visited, required this.found});

  /// 已遍历的文件数（含不支持的文件）。
  final int visited;

  /// 已发现的 PDF / EPUB 数。
  final int found;
}

sealed class ScanEvent {
  const ScanEvent();
}

class ScanProgressEvent extends ScanEvent {
  const ScanProgressEvent(this.progress);

  final ScanProgress progress;
}

class ScanDoneEvent extends ScanEvent {
  const ScanDoneEvent(this.files);

  final List<ScannedBook> files;
}

class ScanFailedEvent extends ScanEvent {
  const ScanFailedEvent(this.error);

  final Object error;
}

/// 在后台 isolate 中遍历目录，避免大量文件阻塞界面。
class BookScanService {
  Stream<ScanEvent> scan({required List<String> roots}) {
    late StreamController<ScanEvent> controller;
    Isolate? isolate;
    ReceivePort? events;
    SendPort? control;

    Future<void> cleanup() async {
      control?.send('cancel');
      isolate?.kill(priority: Isolate.immediate);
      isolate = null;
      events?.close();
      events = null;
    }

    controller = StreamController<ScanEvent>(
      onListen: () async {
        events = ReceivePort();
        try {
          isolate = await Isolate.spawn(
            scanBooksInIsolate,
            <String, Object>{'roots': roots, 'port': events!.sendPort},
            debugName: 'book-scan',
          );
        } catch (error) {
          controller.add(ScanFailedEvent(error));
          await controller.close();
          return;
        }
        events!.listen((message) {
          if (message is! Map) return;
          switch (message['type']) {
            case 'control':
              control = message['port'] as SendPort?;
              break;
            case 'progress':
              controller.add(
                ScanProgressEvent(
                  ScanProgress(
                    visited: message['visited'] as int? ?? 0,
                    found: message['found'] as int? ?? 0,
                  ),
                ),
              );
              break;
            case 'done':
              controller.add(
                ScanDoneEvent((message['files'] as List).cast<ScannedBook>()),
              );
              controller.close();
              break;
          }
        });
      },
      onCancel: cleanup,
    );
    return controller.stream;
  }
}

/// isolate 入口：深度优先遍历，进度经端口回传。
void scanBooksInIsolate(Map<String, dynamic> args) {
  final roots = (args['roots'] as List).cast<String>();
  final send = args['port'] as SendPort;
  final control = ReceivePort();
  send.send(<String, Object>{'type': 'control', 'port': control.sendPort});

  var cancelled = false;
  control.listen((message) {
    if (message == 'cancel') cancelled = true;
  });

  final files = <ScannedBook>[];
  final seen = <String>{};
  final stack = <String>[];
  for (final root in roots) {
    if (Directory(root).existsSync()) stack.add(root);
  }

  var visited = 0;
  final reportClock = Stopwatch()..start();

  while (stack.isNotEmpty && !cancelled) {
    final directoryPath = stack.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = Directory(directoryPath).listSync(followLinks: false);
    } catch (_) {
      // 无权限或目录已消失：跳过，不中断整体扫描。
      continue;
    }
    for (final entity in entries) {
      if (cancelled) break;
      if (entity is Directory) {
        if (!_skipDirectory(entity.path)) stack.add(entity.path);
        continue;
      }
      if (entity is! File) continue;
      visited++;
      if (reportClock.elapsedMilliseconds >= 150) {
        send.send(<String, Object>{
          'type': 'progress',
          'visited': visited,
          'found': files.length,
        });
        reportClock.reset();
      }

      final name = p.basename(entity.path);
      final format = formatOfFileName(name);
      if (format == null) continue;
      final key = Platform.isWindows ? entity.path.toLowerCase() : entity.path;
      if (!seen.add(key)) continue;

      var size = 0;
      var readable = false;
      try {
        size = entity.lengthSync();
        readable = true;
      } catch (_) {}
      files.add(
        ScannedBook(
          path: entity.path,
          name: name,
          directory: p.dirname(entity.path),
          sizeBytes: size,
          format: format,
          hasValidHeader: readable && _hasExpectedHeader(entity, format),
        ),
      );
    }
  }

  send.send(<String, Object>{
    'type': 'progress',
    'visited': visited,
    'found': files.length,
  });
  files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  send.send(<String, Object>{'type': 'done', 'files': files});
  control.close();
}

bool _hasExpectedHeader(File file, BookFormat format) {
  RandomAccessFile? raf;
  try {
    raf = file.openSync();
    final bytes = raf.readSync(4);
    return switch (format) {
      BookFormat.pdf =>
        bytes.length >= 4 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46,
      BookFormat.epub =>
        bytes.length == 4 &&
            bytes[0] == 0x50 &&
            bytes[1] == 0x4B &&
            bytes[2] == 0x03 &&
            bytes[3] == 0x04,
    };
  } catch (_) {
    return false;
  } finally {
    try {
      raf?.closeSync();
    } catch (_) {}
  }
}

/// Windows 系统目录与开发缓存目录直接跳过，避免全盘扫描过慢。
const Set<String> _skipDirectoryNames = <String>{
  'windows',
  'program files',
  'program files (x86)',
  'programdata',
  r'$recycle.bin',
  'system volume information',
  'appdata',
  'node_modules',
  '.git',
  '.dart_tool',
  '.gradle',
  '.idea',
  '.vscode',
  'windowsapps',
  'pub-cache',
  '.trae',
  '.trae-cn',
};

bool _skipDirectory(String path) {
  final name = p.basename(path).toLowerCase();
  if (_skipDirectoryNames.contains(name)) return true;
  final lower = path.toLowerCase().replaceAll('\\', '/');
  // Android 应用私有目录不可读，遍历只会拖慢速度。
  if (lower.contains('/android/data') || lower.contains('/android/obb')) {
    return true;
  }
  return false;
}
