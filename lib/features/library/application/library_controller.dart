import 'dart:async';
import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repos/document_repository.dart';
import '../../../data/repos/progress_repository.dart';

/// 一次导入操作的结果汇总，供界面提示。
class ImportReport {
  const ImportReport({
    this.imported = const <DocumentRow>[],
    this.duplicates = const <DocumentRow>[],
    this.failures = const <String>[],
    this.cancelled = false,
  });

  final List<DocumentRow> imported;
  final List<DocumentRow> duplicates;
  final List<String> failures;
  final bool cancelled;

  bool get hasAnything => imported.isNotEmpty || duplicates.isNotEmpty || failures.isNotEmpty;
}

/// 书架状态：文档列表 + 导入进度。
class LibraryController extends ChangeNotifier {
  LibraryController({
    required DocumentRepository documents,
    required ProgressRepository progress,
  }) : _documents = documents,
       _progress = progress {
    _subscription = _documents.watchLibrary().listen(
      (rows) {
        _items = rows;
        _loading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _loading = false;
        _errorMessage = '读取书架失败：$error';
        notifyListeners();
      },
    );
    // EPUB 的进度只存在 reading_progress.position，书架需要单独订阅。
    _progressSubscription = _progress.watchAll().listen(
      (rows) {
        _positions = <String, double>{
          for (final row in rows)
            if (row.position != null) row.documentId: row.position!,
        };
        notifyListeners();
      },
      onError: (Object error) {
        AppLogger.log(
          '读取阅读进度失败',
          level: 'WARN',
          tag: 'LIBRARY',
          detail: '$error',
        );
      },
    );
  }

  final DocumentRepository _documents;
  final ProgressRepository _progress;
  StreamSubscription<List<DocumentRow>>? _subscription;
  StreamSubscription<List<ReadingProgressRow>>? _progressSubscription;

  List<DocumentRow> _items = const <DocumentRow>[];
  Map<String, double> _positions = const <String, double>{};
  bool _loading = true;
  bool _importing = false;
  String? _errorMessage;

  List<DocumentRow> get items => _items;
  bool get loading => _loading;
  bool get importing => _importing;
  String? get errorMessage => _errorMessage;

  /// EPUB 的阅读位置（0–1）；未读过为 null。
  double? positionOf(String documentId) => _positions[documentId];

  /// 调起系统文件选择器，逐个导入。
  Future<ImportReport> pickAndImport() async {
    AppLogger.log('打开文件选择器', tag: 'IMPORT');
    final picked = await FilePicker.pickFiles(
      dialogTitle: '选择 PDF / EPUB',
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'epub'],
    );
    AppLogger.log(
      '文件选择器返回 ${picked.length} 个文件',
      tag: 'IMPORT',
      detail: picked
          .map((f) => 'name=${f.name} size=${f.lengthSync()} path=${f.path}')
          .join('; '),
    );
    if (picked.isEmpty) {
      return const ImportReport(cancelled: true);
    }
    return _importFiles(picked);
  }

  /// 取回上一次被打断的选择结果并继续导入。
  ///
  /// Android 可能在文件选择器打开期间销毁 Activity 甚至整个进程（低内存时）。
  /// 用户选完文件回到应用时看起来就是「导入到一半闪退」，且系统不会留下崩溃
  /// 记录；选择结果被插件存进 LostDataStore，只有主动取回才能继续导入。
  Future<ImportReport?> recoverLostImport() async {
    final platform = FilePickerPlatform.instance;
    if (platform is! FilePickerAndroid) return null;
    LostFilePickerResult? lost;
    try {
      lost = await platform.retrieveLostData();
    } catch (error, stack) {
      AppLogger.log(
        '取回上次导入结果失败',
        level: 'WARN',
        tag: 'IMPORT',
        detail: '$error\n$stack',
      );
      return null;
    }
    if (lost == null) return null;
    if (lost.exception != null) {
      AppLogger.log(
        '上次导入在选择阶段中断',
        level: 'WARN',
        tag: 'IMPORT',
        detail: '${lost.exception!.code} ${lost.exception!.message ?? ''}',
      );
      return null;
    }
    if (lost.files.isEmpty) return null;
    AppLogger.log(
      '恢复上次被打断的导入',
      level: 'WARN',
      tag: 'IMPORT',
      detail: lost.files
          .map((f) => 'name=${f.name} path=${f.path}')
          .join('; '),
    );
    return _importFiles(lost.files);
  }

  Future<ImportReport> _importFiles(List<PlatformFile> picked) async {
    _importing = true;
    notifyListeners();

    final imported = <DocumentRow>[];
    final duplicates = <DocumentRow>[];
    final failures = <String>[];
    try {
      for (final file in picked) {
        final path = file.path;
        if (path == null) {
          failures.add('无法读取文件：${file.name}');
          AppLogger.log(
            '选择器未返回本地路径',
            level: 'WARN',
            tag: 'IMPORT',
            detail: 'name=${file.name}',
          );
          continue;
        }
        AppLogger.log('开始导入', tag: 'IMPORT', detail: '${file.name} → $path');
        final outcome = await _documents.importFile(File(path));
        switch (outcome) {
          case ImportSuccess(document: final document):
            imported.add(document);
            AppLogger.log(
              '导入成功',
              tag: 'IMPORT',
              detail: '${file.name} id=${document.id} pages=${document.pageCount}',
            );
          case ImportDuplicate(document: final document):
            duplicates.add(document);
            AppLogger.log('导入重复，跳过', tag: 'IMPORT', detail: file.name);
          case ImportInvalid(reason: final reason):
            failures.add('${file.name}：$reason');
            AppLogger.log(
              '导入失败',
              level: 'WARN',
              tag: 'IMPORT',
              detail: '${file.name}：$reason',
            );
        }
      }
    } catch (error, stack) {
      // 导入链路上的异常（含插件返回的 PlatformException）都收口成失败提示，
      // 不能让书架页面静默卡死。
      failures.add('导入出错：$error');
      AppLogger.log(
        '导入过程异常',
        level: 'ERROR',
        tag: 'IMPORT',
        detail: '$error\n$stack',
      );
    } finally {
      _importing = false;
      notifyListeners();
    }
    return ImportReport(imported: imported, duplicates: duplicates, failures: failures);
  }

  Future<void> delete(String documentId) async {
    await _documents.delete(documentId);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(_progressSubscription?.cancel());
    super.dispose();
  }
}
