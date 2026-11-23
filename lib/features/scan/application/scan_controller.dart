import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform/storage_access.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repos/document_repository.dart';
import 'book_scan_service.dart';

/// 扫描结果导入汇总。
class ScanImportSummary {
  const ScanImportSummary({
    this.imported = 0,
    this.duplicates = 0,
    this.failures = const <String>[],
  });

  final int imported;
  final int duplicates;
  final List<String> failures;

  bool get hasAnything => imported > 0 || duplicates > 0 || failures.isNotEmpty;

  String get message {
    final parts = <String>[
      if (imported > 0) '成功导入 $imported 本',
      if (duplicates > 0) '$duplicates 本已在书架',
      if (failures.isNotEmpty) '${failures.length} 个失败',
    ];
    if (parts.isEmpty) return '';
    final detail = failures.isEmpty ? '' : '\n${failures.first}';
    return '${parts.join('，')}$detail';
  }
}

/// 扫描本机文件（PDF / EPUB）的页面状态：权限、扫描进度、结果选择、导入。
class ScanController extends ChangeNotifier {
  ScanController({required DocumentRepository documents})
    : _documents = documents;

  final DocumentRepository _documents;

  StorageAccessStatus _access = StorageAccessStatus.notRequired;
  bool _checkingAccess = true;
  bool _scanning = false;
  bool _cancelled = false;
  int _visited = 0;
  int _found = 0;
  List<ScannedBook> _results = const <ScannedBook>[];
  final Set<String> _selected = <String>{};
  Set<String> _libraryKeys = <String>{};
  final Map<String, String> _issues = <String, String>{};
  bool _importing = false;
  String? _errorMessage;
  StreamSubscription<ScanEvent>? _subscription;

  StorageAccessStatus get access => _access;
  bool get checkingAccess => _checkingAccess;
  bool get scanning => _scanning;
  bool get cancelled => _cancelled;
  int get visited => _visited;
  int get found => _found;
  List<ScannedBook> get results => _results;
  Set<String> get selected => _selected;
  bool get importing => _importing;
  String? get errorMessage => _errorMessage;
  bool get needsPermission => _access == StorageAccessStatus.denied;

  bool isSelected(String path) => _selected.contains(path);

  bool inLibrary(ScannedBook file) => _libraryKeys.contains(_libraryKey(file.name, file.sizeBytes));

  String? issueOf(ScannedBook file) => _issues[file.path];

  Future<void> prepare() async {
    _checkingAccess = true;
    notifyListeners();
    try {
      _access = await StorageAccess.status();
    } catch (error) {
      _errorMessage = '读取存储权限状态失败：$error';
    }
    await _refreshLibraryKeys();
    _checkingAccess = false;
    notifyListeners();
  }

  /// 从系统设置页返回后刷新权限状态。
  Future<void> refreshAccess() async {
    if (!_checkingAccess) {
      final status = await StorageAccess.status();
      if (status != _access) {
        _access = status;
        notifyListeners();
      }
    }
  }

  Future<void> requestAccess() async {
    try {
      await StorageAccess.request();
      _access = await StorageAccess.status();
    } catch (error) {
      _errorMessage = '申请存储权限失败：$error';
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_scanning) return;
    _access = await StorageAccess.status();
    if (_access == StorageAccessStatus.denied) {
      notifyListeners();
      return;
    }
    _scanning = true;
    _cancelled = false;
    _visited = 0;
    _found = 0;
    _results = const <ScannedBook>[];
    _selected.clear();
    _issues.clear();
    _errorMessage = null;
    notifyListeners();

    final roots = await _scanRoots();
    AppLogger.log('开始扫描本机文件', tag: 'SCAN', detail: roots.join(' | '));
    _subscription = BookScanService().scan(roots: roots).listen(
      (event) {
        switch (event) {
          case ScanProgressEvent(:final progress):
            _visited = progress.visited;
            _found = progress.found;
            notifyListeners();
            break;
          case ScanDoneEvent(:final files):
            _results = files;
            _found = files.length;
            _scanning = false;
            AppLogger.log(
              '扫描完成',
              tag: 'SCAN',
              detail: 'files=${files.length} visited=$_visited',
            );
            notifyListeners();
            break;
          case ScanFailedEvent(:final error):
            _scanning = false;
            _errorMessage = '扫描失败：$error';
            AppLogger.log(
              '扫描失败',
              level: 'WARN',
              tag: 'SCAN',
              detail: '$error',
            );
            notifyListeners();
            break;
        }
      },
      onError: (Object error) {
        _scanning = false;
        _errorMessage = '扫描失败：$error';
        notifyListeners();
      },
      onDone: () {
        if (_scanning) {
          _scanning = false;
          notifyListeners();
        }
      },
    );
  }

  void cancelScan() {
    if (!_scanning) return;
    _subscription?.cancel();
    _subscription = null;
    _scanning = false;
    _cancelled = true;
    _results = const <ScannedBook>[];
    _selected.clear();
    notifyListeners();
  }

  void toggleSelected(String path) {
    if (!_selected.remove(path)) _selected.add(path);
    notifyListeners();
  }

  void selectAll() {
    _selected
      ..clear()
      ..addAll(_results.map((f) => f.path));
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<ScanImportSummary> importSelected() async {
    if (_importing || _selected.isEmpty) {
      return const ScanImportSummary();
    }
    _importing = true;
    notifyListeners();

    var imported = 0;
    var duplicates = 0;
    final failures = <String>[];
    final byPath = <String, ScannedBook>{
      for (final file in _results) file.path: file,
    };
    for (final path in _selected.toList()) {
      final file = byPath[path];
      if (file == null) continue;
      final outcome = await _documents.importFile(File(path));
      switch (outcome) {
        case ImportSuccess(:final document):
          imported++;
          AppLogger.log(
            '扫描导入成功',
            tag: 'IMPORT',
            detail: '${file.name} id=${document.id}',
          );
          break;
        case ImportDuplicate():
          duplicates++;
          break;
        case ImportInvalid(:final reason):
          failures.add('${file.name}：$reason');
          _issues[path] = reason;
          AppLogger.log(
            '扫描导入失败',
            level: 'WARN',
            tag: 'IMPORT',
            detail: '${file.name}：$reason',
          );
          break;
      }
    }

    _importing = false;
    _selected.clear();
    await _refreshLibraryKeys();
    notifyListeners();
    return ScanImportSummary(
      imported: imported,
      duplicates: duplicates,
      failures: failures,
    );
  }

  Future<void> _refreshLibraryKeys() async {
    try {
      final documents = await _documents.list();
      _libraryKeys = documents
          .map((doc) => '${doc.title.toLowerCase()}|${doc.fileSize}')
          .toSet();
    } catch (_) {
      _libraryKeys = <String>{};
    }
  }

  String _libraryKey(String fileName, int sizeBytes) {
    final name = p.basename(fileName);
    final dot = name.lastIndexOf('.');
    final title = (dot > 0 ? name.substring(0, dot) : name).toLowerCase();
    return '$title|$sizeBytes';
  }

  Future<List<String>> _scanRoots() async {
    if (Platform.isAndroid) {
      final roots = <String>[];
      final internal = await StorageAccess.androidRoot();
      if (internal != null) roots.add(internal);
      // 外置 SD 卡：/storage 下除 emulated/self 之外的可读目录。
      try {
        for (final entity in Directory('/storage').listSync()) {
          if (entity is! Directory) continue;
          final name = p.basename(entity.path);
          if (name == 'emulated' || name == 'self') continue;
          roots.add(entity.path);
        }
      } catch (_) {}
      return roots;
    }

    final roots = <String>[];
    final home = Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'];
    if (home != null) {
      for (final sub in <String>['Downloads', 'Documents', 'Desktop', 'OneDrive']) {
        final dir = p.join(home, sub);
        if (Directory(dir).existsSync()) roots.add(dir);
      }
    }
    if (Platform.isWindows) {
      // 其它固定磁盘整盘扫描；系统盘只扫用户目录，避免耗时过长。
      for (var code = 68; code <= 90; code++) {
        final drive = '${String.fromCharCode(code)}:\\';
        if (Directory(drive).existsSync()) roots.add(drive);
      }
    }
    if (roots.isEmpty && home != null) roots.add(home);
    return roots;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// 文件大小展示：B / KB / MB / GB。
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  final mb = kb / 1024;
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}
