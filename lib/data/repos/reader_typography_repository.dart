import '../../core/ebook/epub_typography.dart';
import '../db/app_database.dart';

/// EPUB 排版设置：字号档位与行距档位，存 `app_meta`，全局生效。
class ReaderTypographyRepository {
  ReaderTypographyRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  static const String fontKey = 'reader.epub.font_level';
  static const String lineSpacingKey = 'reader.epub.line_spacing_level';

  Future<EpubTypography> load() async {
    final rows = await _db.select(_db.appMeta).get();
    final values = <String, String>{for (final row in rows) row.key: row.value};
    final font = int.tryParse(values[fontKey] ?? '');
    final line = int.tryParse(values[lineSpacingKey] ?? '');
    return EpubTypography(
      fontLevel: (font ?? 2).clamp(0, EpubTypography.fontSizes.length - 1),
      lineSpacingLevel: (line ?? 0).clamp(
        0,
        EpubTypography.lineSpacings.length - 1,
      ),
    );
  }

  Future<void> save(EpubTypography typography) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.appMeta, <AppMetaCompanion>[
        AppMetaCompanion.insert(
          key: fontKey,
          value: '${typography.fontLevel}',
        ),
        AppMetaCompanion.insert(
          key: lineSpacingKey,
          value: '${typography.lineSpacingLevel}',
        ),
      ]);
    });
  }
}
