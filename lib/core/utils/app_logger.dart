import 'dart:io';

import 'package:flutter/foundation.dart';

/// 全局运行日志。
///
/// 写入位置优先取 `HPR_LOG_FILE`（由 `run_windows.ps1` 指向 `logs/latest.log`），
/// 否则退回应用私有目录下的 `logs/app.log`，保证无控制台时也能留痕。
abstract final class AppLogger {
  static File? _file;
  static File? _sessionMarker;
  static bool _handlersInstalled = false;

  /// 脚本已把 stdout 重定向进同一个日志文件时不再 debugPrint，避免同一行写两遍。
  static bool _mirrorToConsole = true;

  /// 当前日志文件绝对路径；未初始化时为空串。
  static String get logPath => _file?.path ?? '';

  /// 初始化日志文件并安装全局异常捕获。
  ///
  /// [fallbackDir] 用于没有 `HPR_LOG_FILE` 的场景（如移动端），重复调用不会覆盖已绑定的文件。
  static void init({String? fallbackDir}) {
    if (_file != null) return;
    final envPath = Platform.environment['HPR_LOG_FILE'];
    final String? path;
    if (envPath != null && envPath.trim().isNotEmpty) {
      path = envPath;
      _mirrorToConsole = false;
    } else if (fallbackDir != null && fallbackDir.isNotEmpty) {
      path = '$fallbackDir${Platform.pathSeparator}logs${Platform.pathSeparator}app.log';
    } else {
      path = null;
    }
    if (path == null) return;

    final file = File(path);
    try {
      file.parent.createSync(recursive: true);
      if (!file.existsSync() || file.lengthSync() == 0) {
        // 先写 BOM：Windows PowerShell 5 默认按 ANSI 读取，带 BOM 才不会中文乱码。
        file.writeAsStringSync('\uFEFF', flush: true);
      }
    } catch (error) {
      debugPrint('日志文件不可写：$error');
      return;
    }
    _file = file;

    if (!_handlersInstalled) {
      _installHandlers();
      _handlersInstalled = true;
    }
    log('应用启动', tag: 'BOOT', detail: '日志文件 $path');
  }

  /// 启动自检：在日志文件同目录写一个运行标记。
  ///
  /// 上次的运行标记还在，说明上次进程没有走正常退出（闪退、被系统杀死、强杀），
  /// 这种情况下应用自身的日志往往戛然而止，这里先补一条定性记录。
  static void beginSession() {
    final file = _file;
    if (file == null) return;
    final marker = File(
      '${file.parent.path}${Platform.pathSeparator}session.marker',
    );
    _sessionMarker = marker;
    try {
      if (marker.existsSync()) {
        final last = marker.readAsStringSync().trim();
        log(
          '上次未正常退出',
          level: 'WARN',
          tag: 'BOOT',
          detail: '上次启动于 $last，未写结束标记（闪退 / 被系统杀死 / 强杀）',
        );
      }
    } catch (_) {
      // 读取失败不影响启动。
    }
    try {
      marker.writeAsStringSync(_stamp(), flush: true);
    } catch (_) {
      // 写标记失败只影响自检，不阻断应用。
    }
  }

  /// 正常退出：删除运行标记并记一条结束日志。
  static void endSession({String reason = '应用正常退出'}) {
    final marker = _sessionMarker;
    if (marker == null) return;
    _sessionMarker = null;
    try {
      if (marker.existsSync()) marker.deleteSync();
    } catch (_) {
      // 删除失败会让下次启动误报，但不应阻断退出。
    }
    log(reason, tag: 'BOOT');
  }

  /// 追加一行日志；[detail] 为补充信息，[error]/[stack] 用于异常。
  static void log(
    String message, {
    String level = 'INFO',
    String tag = 'APP',
    String? detail,
    Object? error,
    StackTrace? stack,
  }) {
    final buffer = StringBuffer('[${_stamp()}] [$level] [$tag] $message');
    if (detail != null && detail.isNotEmpty) buffer.write(' | $detail');
    if (error != null) buffer.write('\n    error: $error');
    if (stack != null) buffer.write('\n${stack.toString().trimRight()}');

    final line = buffer.toString();
    final file = _file;
    if (file != null) {
      try {
        file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      } catch (_) {
        // 日志失败不能影响主流程。
      }
    }
    if (kDebugMode && _mirrorToConsole) debugPrint(line);
  }

  static void _installHandlers() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      log(
        '框架异常',
        level: 'ERROR',
        tag: 'FRAME',
        detail: details.library,
        error: details.exceptionAsString(),
        stack: details.stack,
      );
      if (previousOnError != null) {
        previousOnError(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      log('未捕获异步异常', level: 'ERROR', tag: 'ASYNC', error: error, stack: stack);
      return true;
    };
  }

  static String _stamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)} '
        '${two(now.hour)}:${two(now.minute)}:${two(now.second)}.${three(now.millisecond)}';
  }
}
