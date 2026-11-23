import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_pdf_reader/app/providers.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/reader_entry_position_repository.dart';
import 'package:home_pdf_reader/features/bookmarks/presentation/bookmark_panel.dart';
import 'package:home_pdf_reader/features/reader/application/reader_session.dart';
import 'package:home_pdf_reader/features/reader/presentation/reader_shell.dart';

/// 外壳返回书架路径：Esc（Windows）与面板「书架」按钮。
///
/// 安卓返回键走 PopScope，另有集成冒烟覆盖；这里用组件测试驱动键盘事件
/// 验证 Esc 与按钮路由，PDF / EPUB 共用外壳，行为一致。
void main() {
  testWidgets('面板打开时按 Esc 只关面板，不离开阅读页', (tester) async {
    final session = _FakeSession();
    await _pumpShell(tester, session);
    expect(find.byType(BookmarkPanel), findsNothing);

    session.openBookmarks();
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkPanel), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(session.bookmarksVisible, isFalse);
    expect(find.byType(BookmarkPanel), findsNothing);
    expect(_onBookshelf(tester), isFalse);
  });

  testWidgets('面板关闭时按 Esc 返回书架', (tester) async {
    final session = _FakeSession();
    await _pumpShell(tester, session);
    expect(_onBookshelf(tester), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_onBookshelf(tester), isTrue);
    expect(find.byType(BookmarkPanel), findsNothing);
  });

  testWidgets('面板「书架」按钮返回书架（任意页签可见）', (tester) async {
    final session = _FakeSession();
    await _pumpShell(tester, session);
    session.openBookmarks();
    await tester.pumpAndSettle();

    await tester.tap(find.text('书架'));
    await tester.pumpAndSettle();
    expect(_onBookshelf(tester), isTrue);
    expect(find.byType(BookmarkPanel), findsNothing);
  });
}

bool _onBookshelf(WidgetTester tester) =>
    find.byKey(const ValueKey<String>('bookshelf-probe')).evaluate().isNotEmpty;

Future<void> _pumpShell(WidgetTester tester, _FakeSession session) async {
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
  await tester.pumpAndSettle();
}

/// 位置记忆只提供空实现：测试不落库，入口回退贴右上角。
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
