import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pdf/pdf_engine.dart';
import '../core/pdf/pdfrx_engine.dart';
import '../core/platform/system_gesture_exclusion.dart';
import '../data/db/app_database.dart';
import '../data/repos/bookmark_repository.dart';
import '../data/repos/document_repository.dart';
import '../data/repos/progress_repository.dart';
import '../data/repos/reader_entry_position_repository.dart';
import '../data/repos/reader_typography_repository.dart';
import '../data/repos/toc_repository.dart';

/// 依赖注入：全部使用 riverpod provider，禁止全局可变单例。
final pdfEngineProvider = Provider<PdfEngine>((ref) => const PdfrxEngine());

/// Android 系统手势排除区；非 Android 平台内部直接跳过。
final systemGestureExclusionProvider =
    Provider<SystemGestureExclusionService>(
      (ref) => const SystemGestureExclusionService(),
    );

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(
    database: ref.watch(databaseProvider),
    engine: ref.watch(pdfEngineProvider),
  ),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(database: ref.watch(databaseProvider)),
);

final bookmarkRepositoryProvider = Provider<BookmarkRepository>(
  (ref) => BookmarkRepository(database: ref.watch(databaseProvider)),
);

final tocRepositoryProvider = Provider<TocRepository>(
  (ref) => TocRepository(database: ref.watch(databaseProvider)),
);

final readerEntryPositionRepositoryProvider =
    Provider<ReaderEntryPositionRepository>(
      (ref) =>
          ReaderEntryPositionRepository(database: ref.watch(databaseProvider)),
    );

final readerTypographyRepositoryProvider = Provider<ReaderTypographyRepository>(
  (ref) => ReaderTypographyRepository(database: ref.watch(databaseProvider)),
);
