import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_logger.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class HomePdfReaderApp extends ConsumerWidget {
  const HomePdfReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SessionGuard(
      child: MaterialApp.router(
        title: 'HomePdfReader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

/// 正常退出时清掉运行标记；闪退时来不及清，下次启动由 [AppLogger.beginSession] 报出。
class _SessionGuard extends StatefulWidget {
  const _SessionGuard({required this.child});

  final Widget child;

  @override
  State<_SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<_SessionGuard> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      // Android 上从根页面返回 / 进程被正常关闭时宿主视图会 detach。
      onDetach: () => AppLogger.endSession(reason: '应用正常退出（宿主视图 detach）'),
      // Windows 上点关闭窗口会先询问，确认退出后再清标记。
      onExitRequested: () async {
        AppLogger.endSession(reason: '应用正常退出（关闭窗口）');
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
