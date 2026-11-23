import 'package:drift/drift.dart';

/// 文档库。所有时间字段为 epoch 毫秒。
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();

  /// 文件内容哈希，用于去重与文件一致性校验。
  TextColumn get sha256 => text().unique()();

  TextColumn get title => text()();
  TextColumn get author => text().nullable()();

  /// 文档格式：`pdf` / `epub`。老数据默认 `pdf`。
  TextColumn get format => text().withDefault(const Constant('pdf'))();

  /// 相对应用私有目录的路径，禁止存绝对路径。
  TextColumn get relPath => text()();
  TextColumn get coverRelPath => text().nullable()();

  /// PDF 页数；EPUB 无页概念，为 null。
  IntColumn get pageCount => integer().nullable()();
  IntColumn get fileSize => integer()();

  /// 是否具备可用文字层（扫描件为 false）。
  BoolColumn get hasTextLayer => boolean()();
  IntColumn get addedAt => integer()();
  IntColumn get lastOpenedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReadingProgressRow')
class ReadingProgress extends Table {
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();

  /// PDF 阅读页（0 基）；EPUB 为 null。
  IntColumn get pageIndex => integer().nullable()();

  /// EPUB 阅读位置，0–1 的比例；PDF 为 null。
  RealColumn get position => real().nullable()();

  RealColumn get offsetY => real().withDefault(const Constant(0))();
  RealColumn get zoom => real().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();

  /// PDF 目标页（0 基）；EPUB 为 null。
  IntColumn get pageIndex => integer().nullable()();

  /// EPUB 目标位置，0–1；PDF 为 null。
  RealColumn get position => real().nullable()();

  /// 页内归一化 y，0–1。
  RealColumn get posY => real()();
  TextColumn get label => text()();
  TextColumn get excerpt => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HighlightRow')
class Highlights extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageIndex => integer()();

  /// `[[x0,y0,x1,y1], ...]` 归一化矩形，按阅读顺序。
  TextColumn get rectsJson => text()();
  TextColumn get textSnapshot => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get color => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TocEntryRow')
class TocEntries extends Table {
  TextColumn get id => text()();
  TextColumn get documentId => text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get level => integer()();

  /// PDF 目标页（0 基）；EPUB 为 null。
  IntColumn get pageIndex => integer().nullable()();

  /// EPUB 目标文件（相对 OPF 目录、已 URL 解码）；PDF 为 null。
  TextColumn get href => text().nullable()();

  /// EPUB 目标片段（`#` 之后）；无片段为 null。
  TextColumn get fragment => text().nullable()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
