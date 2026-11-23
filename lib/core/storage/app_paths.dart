import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 应用私有目录解析。数据库中只允许存储相对本目录的路径。
abstract final class AppPaths {
  static Directory? _root;

  /// 启动期调用一次，可重复调用（幂等）。
  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _root = dir;
    await pdfsDir.create(recursive: true);
    await epubsDir.create(recursive: true);
    await coversDir.create(recursive: true);
  }

  static Directory get root {
    final dir = _root;
    if (dir == null) {
      throw StateError('AppPaths.init() 尚未调用');
    }
    return dir;
  }

  static Directory get pdfsDir => Directory(p.join(root.path, 'pdfs'));

  static Directory get epubsDir => Directory(p.join(root.path, 'epubs'));

  static Directory get coversDir => Directory(p.join(root.path, 'covers'));

  /// 相对路径 → 绝对文件。
  static File resolve(String relPath) => File(p.join(root.path, relPath));

  /// 绝对路径 → 相对路径（入库用）。
  static String toRelative(String absolutePath) => p.relative(absolutePath, from: root.path);

  /// 枚举现有 PDF 文件（孤儿文件清理用）。
  static Future<List<File>> listPdfFiles() async {
    final dir = pdfsDir;
    if (!dir.existsSync()) return <File>[];
    return dir
        .list()
        .where((e) => e is File && e.path.toLowerCase().endsWith('.pdf'))
        .cast<File>()
        .toList();
  }
}
