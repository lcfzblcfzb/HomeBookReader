import 'package:go_router/go_router.dart';

import '../features/library/presentation/library_page.dart';
import '../features/reader/presentation/reader_host_page.dart';
import '../features/scan/presentation/scan_page.dart';
import '../features/settings/presentation/settings_page.dart';

/// 路由：书架为首页，阅读页只接收 documentId。
abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'library',
        builder: (context, state) => const LibraryPage(),
      ),
      GoRoute(
        path: '/reader/:documentId',
        name: 'reader',
        builder: (context, state) =>
            ReaderHostPage(documentId: state.pathParameters['documentId']!),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ScanPage(),
      ),
    ],
  );
}
