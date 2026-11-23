import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:home_pdf_reader/app/providers.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/reader_entry_position_repository.dart';
import 'package:home_pdf_reader/features/bookmarks/presentation/bookmark_panel.dart';
import 'package:home_pdf_reader/features/reader/application/reader_session.dart';
import 'package:home_pdf_reader/features/reader/presentation/reader_shell.dart';

/// M1-017 冒烟：真实 Windows 窗口里验证阅读页返回书架的三条路径。
///
/// Esc（Windows 替代安卓返回键）先关面板再回书架；面板「书架」按钮直接回书架。
/// 不导入真实文档：flutter test 拉起的 App 进程被环境拒绝写 AppData/Temp
/// （导入需要复制文件到私有目录），而 Esc 行为只依赖外壳与路由，
/// 用假会话驱动即可覆盖「真实窗口 + 真实键盘事件」这条关键路径。
/// 运行：flutter test integration_test/m1_reader_return_smoke_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Esc 关面板 → Esc 回书架 → 面板按钮回书架', (tester) async {
    final session = _FakeSession();
    final router = GoRouter(
      initialLocation: '/reader/doc1',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const ColoredBox(
            color: Colors.white,
            key: ValueKey<String>('bookshelf-probe'),
            child: SizedBox.expand(),
          ),
        ),
        GoRoute(
          path: '/reader/:documentId',
          builder: (_, _) => ReaderShell(
            session: session,
            bodyBuilder: (_) =>
                const ColoredBox(color: Colors.black, child: SizedBox.expand()),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readerEntryPositionRepositoryProvider.overrideWithValue(
            _FakeEntryPositionRepository(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(_bookshelfProbe, findsNothing, reason: '应处于阅读页');

    // 1) 面板打开时 Esc：只关面板，不离开阅读页。
    await _openPanel(tester, session);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(session.bookmarksVisible, isFalse, reason: 'Esc 应先关面板');
    expect(find.byType(BookmarkPanel), findsNothing);
    expect(_bookshelfProbe, findsNothing);

    // 2) 面板关闭时 Esc：返回书架。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_bookshelfProbe, findsOneWidget, reason: 'Esc 应返回书架');

    // 3) 面板「书架」按钮：直接回书架。
    router.go('/reader/doc1');
    await tester.pumpAndSettle();
    expect(_bookshelfProbe, findsNothing);
    await _openPanel(tester, session);
    await tester.tap(find.text('书架'));
    await tester.pumpAndSettle();
    expect(_bookshelfProbe, findsOneWidget, reason: '「书架」按钮应返回书架');
    expect(find.byType(BookmarkPanel), findsNothing);
  });
}

final _bookshelfProbe = find.byKey(const ValueKey<String>('bookshelf-probe'));

/// 打开书签面板：入口位置记忆为空时贴右上角，点右上角入口条。
Future<void> _openPanel(WidgetTester tester, _FakeSession session) async {
  session.openBookmarks();
  await tester.pumpAndSettle();
  expect(find.byType(BookmarkPanel), findsOneWidget);
}

/// 位置记忆只提供空实现：不落库，入口回退贴右上角。
class _FakeEntryPositionRepository implements ReaderEntryPositionRepository {
  @override
  Future<double?> load({required bool isLandscape}) async => null;

  @override
  Future<void> save({
    required bool isLandscape,
    required double ratio,
  }) async {}
}

/// 只驱动外壳所需的最小状态：面板可见性可切换，其余给中性值。
class _FakeSession extends ReaderSession {
  bool _panelVisible = false;

  @override
  DocumentRow? get document => null;
  @override
  bool get loading => false;
  @override
  String? get errorMessage => null;
  @override
  bool get bookmarksVisible => _panelVisible;
  @override
  ReaderPanelTab get panelTab => ReaderPanelTab.bookmarks;
  @override
  List<BookmarkRow> get bookmarkItems => const <BookmarkRow>[];
  @override
  List<TocEntryRow> get tocItems => const <TocEntryRow>[];
  @override
  bool get tocLoading => false;
  @override
  String? get tocError => null;
  @override
  bool get hasTextLayer => true;
  @override
  int? get currentPageIndex => null;
  @override
  String? get currentHref => null;
  @override
  bool get supportsTypography => false;

  @override
  void openBookmarks() {
    _panelVisible = true;
    notifyListeners();
  }

  @override
  void closeBookmarks() {
    _panelVisible = false;
    notifyListeners();
  }

  @override
  void selectPanelTab(ReaderPanelTab tab) {}

  @override
  void nextPage() {}

  @override
  void previousPage() {}

  @override
  Future<void> jumpToTocEntry(TocEntryRow entry) async {}

  @override
  Future<void> jumpToBookmark(BookmarkRow bookmark) async {}

  @override
  Future<BookmarkRow> addBookmark({String? label}) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {}

  @override
  Future<void> flushProgress() async {}

  @override
  bool isTocEntryCurrent(TocEntryRow entry) => false;

  @override
  String tocEntryLocation(TocEntryRow entry) => '';

  @override
  String bookmarkLocation(BookmarkRow bookmark) => '';

  @override
  String? takeTransientMessage() => null;
}
