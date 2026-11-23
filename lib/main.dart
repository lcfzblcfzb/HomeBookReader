import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/app_paths.dart';
import 'core/utils/app_logger.dart';

void main() {
  // 捕获启动期与异步异常，写入 logs/latest.log（由启动脚本通过 HPR_LOG_FILE 指定）。
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLogger.init();
      await AppPaths.init();
      AppLogger.init(fallbackDir: AppPaths.root.path);
      // 启动自检：上次若没写结束标记，这里会在日志里记一条「上次未正常退出」。
      AppLogger.beginSession();
      runApp(const ProviderScope(child: HomePdfReaderApp()));
    },
    (error, stack) {
      AppLogger.log('启动期异常', level: 'ERROR', tag: 'BOOT', error: error, stack: stack);
    },
  );
}
