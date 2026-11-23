import '../db/app_database.dart';

/// 阅读页书签入口的位置记忆：竖屏、横屏各存一份纵向比例。
///
/// 入口贴在当前朝向的右侧边，存 0..1 的比例而不是绝对像素，窗口高度变化
/// （Windows 改窗口大小、不同设备）后仍能还原到相同的相对位置。
/// 读取失败或从未拖动过时返回 null，由界面回退到贴右上角。
///
/// 兼容：M1-012 及以前入口贴顶，记的是横坐标（`reader.entry_x.*`）。
/// 那批数据对纵向没有意义，读取新键缺失时会顺手删除，避免升级后错位。
class ReaderEntryPositionRepository {
  ReaderEntryPositionRepository({required AppDatabase database})
    : _db = database;

  final AppDatabase _db;

  static const String portraitKey = 'reader.entry_y.portrait';
  static const String landscapeKey = 'reader.entry_y.landscape';

  /// 旧版贴顶方案留下的横坐标键，仅用于清理。
  static const String legacyPortraitKey = 'reader.entry_x.portrait';
  static const String legacyLandscapeKey = 'reader.entry_x.landscape';

  Future<double?> load({required bool isLandscape}) async {
    final row = await (_db.select(
      _db.appMeta,
    )..where((t) => t.key.equals(_key(isLandscape)))).getSingleOrNull();
    if (row == null) {
      await _deleteLegacy(isLandscape);
      return null;
    }
    return double.tryParse(row.value);
  }

  Future<void> save({required bool isLandscape, required double ratio}) {
    return _db
        .into(_db.appMeta)
        .insertOnConflictUpdate(
          AppMetaCompanion.insert(
            key: _key(isLandscape),
            value: ratio.clamp(0.0, 1.0).toStringAsFixed(6),
          ),
        );
  }

  /// 老版本的横坐标比例对纵向位置无意义，直接丢弃。
  Future<void> _deleteLegacy(bool isLandscape) {
    final legacy = isLandscape ? legacyLandscapeKey : legacyPortraitKey;
    return (_db.delete(_db.appMeta)..where((t) => t.key.equals(legacy))).go();
  }

  String _key(bool isLandscape) => isLandscape ? landscapeKey : portraitKey;
}
