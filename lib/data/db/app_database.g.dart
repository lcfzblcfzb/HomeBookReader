// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pdf'),
  );
  static const VerificationMeta _relPathMeta = const VerificationMeta(
    'relPath',
  );
  @override
  late final GeneratedColumn<String> relPath = GeneratedColumn<String>(
    'rel_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverRelPathMeta = const VerificationMeta(
    'coverRelPath',
  );
  @override
  late final GeneratedColumn<String> coverRelPath = GeneratedColumn<String>(
    'cover_rel_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasTextLayerMeta = const VerificationMeta(
    'hasTextLayer',
  );
  @override
  late final GeneratedColumn<bool> hasTextLayer = GeneratedColumn<bool>(
    'has_text_layer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_text_layer" IN (0, 1))',
    ),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<int> lastOpenedAt = GeneratedColumn<int>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sha256,
    title,
    author,
    format,
    relPath,
    coverRelPath,
    pageCount,
    fileSize,
    hasTextLayer,
    addedAt,
    lastOpenedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('rel_path')) {
      context.handle(
        _relPathMeta,
        relPath.isAcceptableOrUnknown(data['rel_path']!, _relPathMeta),
      );
    } else if (isInserting) {
      context.missing(_relPathMeta);
    }
    if (data.containsKey('cover_rel_path')) {
      context.handle(
        _coverRelPathMeta,
        coverRelPath.isAcceptableOrUnknown(
          data['cover_rel_path']!,
          _coverRelPathMeta,
        ),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('has_text_layer')) {
      context.handle(
        _hasTextLayerMeta,
        hasTextLayer.isAcceptableOrUnknown(
          data['has_text_layer']!,
          _hasTextLayerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasTextLayerMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      relPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rel_path'],
      )!,
      coverRelPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_rel_path'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      hasTextLayer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_text_layer'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_opened_at'],
      ),
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;

  /// 文件内容哈希，用于去重与文件一致性校验。
  final String sha256;
  final String title;
  final String? author;

  /// 文档格式：`pdf` / `epub`。老数据默认 `pdf`。
  final String format;

  /// 相对应用私有目录的路径，禁止存绝对路径。
  final String relPath;
  final String? coverRelPath;

  /// PDF 页数；EPUB 无页概念，为 null。
  final int? pageCount;
  final int fileSize;

  /// 是否具备可用文字层（扫描件为 false）。
  final bool hasTextLayer;
  final int addedAt;
  final int? lastOpenedAt;
  const DocumentRow({
    required this.id,
    required this.sha256,
    required this.title,
    this.author,
    required this.format,
    required this.relPath,
    this.coverRelPath,
    this.pageCount,
    required this.fileSize,
    required this.hasTextLayer,
    required this.addedAt,
    this.lastOpenedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sha256'] = Variable<String>(sha256);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['format'] = Variable<String>(format);
    map['rel_path'] = Variable<String>(relPath);
    if (!nullToAbsent || coverRelPath != null) {
      map['cover_rel_path'] = Variable<String>(coverRelPath);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    map['file_size'] = Variable<int>(fileSize);
    map['has_text_layer'] = Variable<bool>(hasTextLayer);
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt);
    }
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      sha256: Value(sha256),
      title: Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      format: Value(format),
      relPath: Value(relPath),
      coverRelPath: coverRelPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverRelPath),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      fileSize: Value(fileSize),
      hasTextLayer: Value(hasTextLayer),
      addedAt: Value(addedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      sha256: serializer.fromJson<String>(json['sha256']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      format: serializer.fromJson<String>(json['format']),
      relPath: serializer.fromJson<String>(json['relPath']),
      coverRelPath: serializer.fromJson<String?>(json['coverRelPath']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      hasTextLayer: serializer.fromJson<bool>(json['hasTextLayer']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      lastOpenedAt: serializer.fromJson<int?>(json['lastOpenedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sha256': serializer.toJson<String>(sha256),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'format': serializer.toJson<String>(format),
      'relPath': serializer.toJson<String>(relPath),
      'coverRelPath': serializer.toJson<String?>(coverRelPath),
      'pageCount': serializer.toJson<int?>(pageCount),
      'fileSize': serializer.toJson<int>(fileSize),
      'hasTextLayer': serializer.toJson<bool>(hasTextLayer),
      'addedAt': serializer.toJson<int>(addedAt),
      'lastOpenedAt': serializer.toJson<int?>(lastOpenedAt),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? sha256,
    String? title,
    Value<String?> author = const Value.absent(),
    String? format,
    String? relPath,
    Value<String?> coverRelPath = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
    int? fileSize,
    bool? hasTextLayer,
    int? addedAt,
    Value<int?> lastOpenedAt = const Value.absent(),
  }) => DocumentRow(
    id: id ?? this.id,
    sha256: sha256 ?? this.sha256,
    title: title ?? this.title,
    author: author.present ? author.value : this.author,
    format: format ?? this.format,
    relPath: relPath ?? this.relPath,
    coverRelPath: coverRelPath.present ? coverRelPath.value : this.coverRelPath,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    fileSize: fileSize ?? this.fileSize,
    hasTextLayer: hasTextLayer ?? this.hasTextLayer,
    addedAt: addedAt ?? this.addedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      format: data.format.present ? data.format.value : this.format,
      relPath: data.relPath.present ? data.relPath.value : this.relPath,
      coverRelPath: data.coverRelPath.present
          ? data.coverRelPath.value
          : this.coverRelPath,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      hasTextLayer: data.hasTextLayer.present
          ? data.hasTextLayer.value
          : this.hasTextLayer,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('format: $format, ')
          ..write('relPath: $relPath, ')
          ..write('coverRelPath: $coverRelPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('fileSize: $fileSize, ')
          ..write('hasTextLayer: $hasTextLayer, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sha256,
    title,
    author,
    format,
    relPath,
    coverRelPath,
    pageCount,
    fileSize,
    hasTextLayer,
    addedAt,
    lastOpenedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.sha256 == this.sha256 &&
          other.title == this.title &&
          other.author == this.author &&
          other.format == this.format &&
          other.relPath == this.relPath &&
          other.coverRelPath == this.coverRelPath &&
          other.pageCount == this.pageCount &&
          other.fileSize == this.fileSize &&
          other.hasTextLayer == this.hasTextLayer &&
          other.addedAt == this.addedAt &&
          other.lastOpenedAt == this.lastOpenedAt);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> sha256;
  final Value<String> title;
  final Value<String?> author;
  final Value<String> format;
  final Value<String> relPath;
  final Value<String?> coverRelPath;
  final Value<int?> pageCount;
  final Value<int> fileSize;
  final Value<bool> hasTextLayer;
  final Value<int> addedAt;
  final Value<int?> lastOpenedAt;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.format = const Value.absent(),
    this.relPath = const Value.absent(),
    this.coverRelPath = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.hasTextLayer = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String sha256,
    required String title,
    this.author = const Value.absent(),
    this.format = const Value.absent(),
    required String relPath,
    this.coverRelPath = const Value.absent(),
    this.pageCount = const Value.absent(),
    required int fileSize,
    required bool hasTextLayer,
    required int addedAt,
    this.lastOpenedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sha256 = Value(sha256),
       title = Value(title),
       relPath = Value(relPath),
       fileSize = Value(fileSize),
       hasTextLayer = Value(hasTextLayer),
       addedAt = Value(addedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? sha256,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? format,
    Expression<String>? relPath,
    Expression<String>? coverRelPath,
    Expression<int>? pageCount,
    Expression<int>? fileSize,
    Expression<bool>? hasTextLayer,
    Expression<int>? addedAt,
    Expression<int>? lastOpenedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sha256 != null) 'sha256': sha256,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (format != null) 'format': format,
      if (relPath != null) 'rel_path': relPath,
      if (coverRelPath != null) 'cover_rel_path': coverRelPath,
      if (pageCount != null) 'page_count': pageCount,
      if (fileSize != null) 'file_size': fileSize,
      if (hasTextLayer != null) 'has_text_layer': hasTextLayer,
      if (addedAt != null) 'added_at': addedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sha256,
    Value<String>? title,
    Value<String?>? author,
    Value<String>? format,
    Value<String>? relPath,
    Value<String?>? coverRelPath,
    Value<int?>? pageCount,
    Value<int>? fileSize,
    Value<bool>? hasTextLayer,
    Value<int>? addedAt,
    Value<int?>? lastOpenedAt,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      title: title ?? this.title,
      author: author ?? this.author,
      format: format ?? this.format,
      relPath: relPath ?? this.relPath,
      coverRelPath: coverRelPath ?? this.coverRelPath,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      hasTextLayer: hasTextLayer ?? this.hasTextLayer,
      addedAt: addedAt ?? this.addedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (relPath.present) {
      map['rel_path'] = Variable<String>(relPath.value);
    }
    if (coverRelPath.present) {
      map['cover_rel_path'] = Variable<String>(coverRelPath.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (hasTextLayer.present) {
      map['has_text_layer'] = Variable<bool>(hasTextLayer.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('format: $format, ')
          ..write('relPath: $relPath, ')
          ..write('coverRelPath: $coverRelPath, ')
          ..write('pageCount: $pageCount, ')
          ..write('fileSize: $fileSize, ')
          ..write('hasTextLayer: $hasTextLayer, ')
          ..write('addedAt: $addedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offsetYMeta = const VerificationMeta(
    'offsetY',
  );
  @override
  late final GeneratedColumn<double> offsetY = GeneratedColumn<double>(
    'offset_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _zoomMeta = const VerificationMeta('zoom');
  @override
  late final GeneratedColumn<double> zoom = GeneratedColumn<double>(
    'zoom',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    pageIndex,
    position,
    offsetY,
    zoom,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('offset_y')) {
      context.handle(
        _offsetYMeta,
        offsetY.isAcceptableOrUnknown(data['offset_y']!, _offsetYMeta),
      );
    }
    if (data.containsKey('zoom')) {
      context.handle(
        _zoomMeta,
        zoom.isAcceptableOrUnknown(data['zoom']!, _zoomMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ReadingProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      ),
      offsetY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}offset_y'],
      )!,
      zoom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zoom'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressRow extends DataClass
    implements Insertable<ReadingProgressRow> {
  final String documentId;

  /// PDF 阅读页（0 基）；EPUB 为 null。
  final int? pageIndex;

  /// EPUB 阅读位置，0–1 的比例；PDF 为 null。
  final double? position;
  final double offsetY;
  final double? zoom;
  final int updatedAt;
  const ReadingProgressRow({
    required this.documentId,
    this.pageIndex,
    this.position,
    required this.offsetY,
    this.zoom,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || pageIndex != null) {
      map['page_index'] = Variable<int>(pageIndex);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<double>(position);
    }
    map['offset_y'] = Variable<double>(offsetY);
    if (!nullToAbsent || zoom != null) {
      map['zoom'] = Variable<double>(zoom);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      documentId: Value(documentId),
      pageIndex: pageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pageIndex),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      offsetY: Value(offsetY),
      zoom: zoom == null && nullToAbsent ? const Value.absent() : Value(zoom),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      pageIndex: serializer.fromJson<int?>(json['pageIndex']),
      position: serializer.fromJson<double?>(json['position']),
      offsetY: serializer.fromJson<double>(json['offsetY']),
      zoom: serializer.fromJson<double?>(json['zoom']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'pageIndex': serializer.toJson<int?>(pageIndex),
      'position': serializer.toJson<double?>(position),
      'offsetY': serializer.toJson<double>(offsetY),
      'zoom': serializer.toJson<double?>(zoom),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ReadingProgressRow copyWith({
    String? documentId,
    Value<int?> pageIndex = const Value.absent(),
    Value<double?> position = const Value.absent(),
    double? offsetY,
    Value<double?> zoom = const Value.absent(),
    int? updatedAt,
  }) => ReadingProgressRow(
    documentId: documentId ?? this.documentId,
    pageIndex: pageIndex.present ? pageIndex.value : this.pageIndex,
    position: position.present ? position.value : this.position,
    offsetY: offsetY ?? this.offsetY,
    zoom: zoom.present ? zoom.value : this.zoom,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingProgressRow copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      position: data.position.present ? data.position.value : this.position,
      offsetY: data.offsetY.present ? data.offsetY.value : this.offsetY,
      zoom: data.zoom.present ? data.zoom.value : this.zoom,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressRow(')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('position: $position, ')
          ..write('offsetY: $offsetY, ')
          ..write('zoom: $zoom, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, pageIndex, position, offsetY, zoom, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressRow &&
          other.documentId == this.documentId &&
          other.pageIndex == this.pageIndex &&
          other.position == this.position &&
          other.offsetY == this.offsetY &&
          other.zoom == this.zoom &&
          other.updatedAt == this.updatedAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressRow> {
  final Value<String> documentId;
  final Value<int?> pageIndex;
  final Value<double?> position;
  final Value<double> offsetY;
  final Value<double?> zoom;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.documentId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.position = const Value.absent(),
    this.offsetY = const Value.absent(),
    this.zoom = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String documentId,
    this.pageIndex = const Value.absent(),
    this.position = const Value.absent(),
    this.offsetY = const Value.absent(),
    this.zoom = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingProgressRow> custom({
    Expression<String>? documentId,
    Expression<int>? pageIndex,
    Expression<double>? position,
    Expression<double>? offsetY,
    Expression<double>? zoom,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (position != null) 'position': position,
      if (offsetY != null) 'offset_y': offsetY,
      if (zoom != null) 'zoom': zoom,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? documentId,
    Value<int?>? pageIndex,
    Value<double?>? position,
    Value<double>? offsetY,
    Value<double?>? zoom,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      position: position ?? this.position,
      offsetY: offsetY ?? this.offsetY,
      zoom: zoom ?? this.zoom,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (offsetY.present) {
      map['offset_y'] = Variable<double>(offsetY.value);
    }
    if (zoom.present) {
      map['zoom'] = Variable<double>(zoom.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('position: $position, ')
          ..write('offsetY: $offsetY, ')
          ..write('zoom: $zoom, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posYMeta = const VerificationMeta('posY');
  @override
  late final GeneratedColumn<double> posY = GeneratedColumn<double>(
    'pos_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageIndex,
    position,
    posY,
    label,
    excerpt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('pos_y')) {
      context.handle(
        _posYMeta,
        posY.isAcceptableOrUnknown(data['pos_y']!, _posYMeta),
      );
    } else if (isInserting) {
      context.missing(_posYMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      ),
      posY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_y'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final String id;
  final String documentId;

  /// PDF 目标页（0 基）；EPUB 为 null。
  final int? pageIndex;

  /// EPUB 目标位置，0–1；PDF 为 null。
  final double? position;

  /// 页内归一化 y，0–1。
  final double posY;
  final String label;
  final String? excerpt;
  final int createdAt;
  const BookmarkRow({
    required this.id,
    required this.documentId,
    this.pageIndex,
    this.position,
    required this.posY,
    required this.label,
    this.excerpt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || pageIndex != null) {
      map['page_index'] = Variable<int>(pageIndex);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<double>(position);
    }
    map['pos_y'] = Variable<double>(posY);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || excerpt != null) {
      map['excerpt'] = Variable<String>(excerpt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageIndex: pageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pageIndex),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
      posY: Value(posY),
      label: Value(label),
      excerpt: excerpt == null && nullToAbsent
          ? const Value.absent()
          : Value(excerpt),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageIndex: serializer.fromJson<int?>(json['pageIndex']),
      position: serializer.fromJson<double?>(json['position']),
      posY: serializer.fromJson<double>(json['posY']),
      label: serializer.fromJson<String>(json['label']),
      excerpt: serializer.fromJson<String?>(json['excerpt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageIndex': serializer.toJson<int?>(pageIndex),
      'position': serializer.toJson<double?>(position),
      'posY': serializer.toJson<double>(posY),
      'label': serializer.toJson<String>(label),
      'excerpt': serializer.toJson<String?>(excerpt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookmarkRow copyWith({
    String? id,
    String? documentId,
    Value<int?> pageIndex = const Value.absent(),
    Value<double?> position = const Value.absent(),
    double? posY,
    String? label,
    Value<String?> excerpt = const Value.absent(),
    int? createdAt,
  }) => BookmarkRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageIndex: pageIndex.present ? pageIndex.value : this.pageIndex,
    position: position.present ? position.value : this.position,
    posY: posY ?? this.posY,
    label: label ?? this.label,
    excerpt: excerpt.present ? excerpt.value : this.excerpt,
    createdAt: createdAt ?? this.createdAt,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      position: data.position.present ? data.position.value : this.position,
      posY: data.posY.present ? data.posY.value : this.posY,
      label: data.label.present ? data.label.value : this.label,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('position: $position, ')
          ..write('posY: $posY, ')
          ..write('label: $label, ')
          ..write('excerpt: $excerpt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    pageIndex,
    position,
    posY,
    label,
    excerpt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageIndex == this.pageIndex &&
          other.position == this.position &&
          other.posY == this.posY &&
          other.label == this.label &&
          other.excerpt == this.excerpt &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int?> pageIndex;
  final Value<double?> position;
  final Value<double> posY;
  final Value<String> label;
  final Value<String?> excerpt;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.position = const Value.absent(),
    this.posY = const Value.absent(),
    this.label = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String documentId,
    this.pageIndex = const Value.absent(),
    this.position = const Value.absent(),
    required double posY,
    required String label,
    this.excerpt = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       posY = Value(posY),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<BookmarkRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageIndex,
    Expression<double>? position,
    Expression<double>? posY,
    Expression<String>? label,
    Expression<String>? excerpt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (position != null) 'position': position,
      if (posY != null) 'pos_y': posY,
      if (label != null) 'label': label,
      if (excerpt != null) 'excerpt': excerpt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int?>? pageIndex,
    Value<double?>? position,
    Value<double>? posY,
    Value<String>? label,
    Value<String?>? excerpt,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      position: position ?? this.position,
      posY: posY ?? this.posY,
      label: label ?? this.label,
      excerpt: excerpt ?? this.excerpt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (posY.present) {
      map['pos_y'] = Variable<double>(posY.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('position: $position, ')
          ..write('posY: $posY, ')
          ..write('label: $label, ')
          ..write('excerpt: $excerpt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HighlightsTable extends Highlights
    with TableInfo<$HighlightsTable, HighlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rectsJsonMeta = const VerificationMeta(
    'rectsJson',
  );
  @override
  late final GeneratedColumn<String> rectsJson = GeneratedColumn<String>(
    'rects_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textSnapshotMeta = const VerificationMeta(
    'textSnapshot',
  );
  @override
  late final GeneratedColumn<String> textSnapshot = GeneratedColumn<String>(
    'text_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageIndex,
    rectsJson,
    textSnapshot,
    note,
    color,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<HighlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIndexMeta);
    }
    if (data.containsKey('rects_json')) {
      context.handle(
        _rectsJsonMeta,
        rectsJson.isAcceptableOrUnknown(data['rects_json']!, _rectsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rectsJsonMeta);
    }
    if (data.containsKey('text_snapshot')) {
      context.handle(
        _textSnapshotMeta,
        textSnapshot.isAcceptableOrUnknown(
          data['text_snapshot']!,
          _textSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HighlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HighlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      )!,
      rectsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rects_json'],
      )!,
      textSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_snapshot'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }
}

class HighlightRow extends DataClass implements Insertable<HighlightRow> {
  final String id;
  final String documentId;
  final int pageIndex;

  /// `[[x0,y0,x1,y1], ...]` 归一化矩形，按阅读顺序。
  final String rectsJson;
  final String? textSnapshot;
  final String? note;
  final int color;
  final int createdAt;
  final int updatedAt;
  const HighlightRow({
    required this.id,
    required this.documentId,
    required this.pageIndex,
    required this.rectsJson,
    this.textSnapshot,
    this.note,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_index'] = Variable<int>(pageIndex);
    map['rects_json'] = Variable<String>(rectsJson);
    if (!nullToAbsent || textSnapshot != null) {
      map['text_snapshot'] = Variable<String>(textSnapshot);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['color'] = Variable<int>(color);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageIndex: Value(pageIndex),
      rectsJson: Value(rectsJson),
      textSnapshot: textSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(textSnapshot),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HighlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HighlightRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageIndex: serializer.fromJson<int>(json['pageIndex']),
      rectsJson: serializer.fromJson<String>(json['rectsJson']),
      textSnapshot: serializer.fromJson<String?>(json['textSnapshot']),
      note: serializer.fromJson<String?>(json['note']),
      color: serializer.fromJson<int>(json['color']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageIndex': serializer.toJson<int>(pageIndex),
      'rectsJson': serializer.toJson<String>(rectsJson),
      'textSnapshot': serializer.toJson<String?>(textSnapshot),
      'note': serializer.toJson<String?>(note),
      'color': serializer.toJson<int>(color),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  HighlightRow copyWith({
    String? id,
    String? documentId,
    int? pageIndex,
    String? rectsJson,
    Value<String?> textSnapshot = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? color,
    int? createdAt,
    int? updatedAt,
  }) => HighlightRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageIndex: pageIndex ?? this.pageIndex,
    rectsJson: rectsJson ?? this.rectsJson,
    textSnapshot: textSnapshot.present ? textSnapshot.value : this.textSnapshot,
    note: note.present ? note.value : this.note,
    color: color ?? this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HighlightRow copyWithCompanion(HighlightsCompanion data) {
    return HighlightRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      rectsJson: data.rectsJson.present ? data.rectsJson.value : this.rectsJson,
      textSnapshot: data.textSnapshot.present
          ? data.textSnapshot.value
          : this.textSnapshot,
      note: data.note.present ? data.note.value : this.note,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HighlightRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('rectsJson: $rectsJson, ')
          ..write('textSnapshot: $textSnapshot, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    pageIndex,
    rectsJson,
    textSnapshot,
    note,
    color,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighlightRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageIndex == this.pageIndex &&
          other.rectsJson == this.rectsJson &&
          other.textSnapshot == this.textSnapshot &&
          other.note == this.note &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HighlightsCompanion extends UpdateCompanion<HighlightRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageIndex;
  final Value<String> rectsJson;
  final Value<String?> textSnapshot;
  final Value<String?> note;
  final Value<int> color;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.rectsJson = const Value.absent(),
    this.textSnapshot = const Value.absent(),
    this.note = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HighlightsCompanion.insert({
    required String id,
    required String documentId,
    required int pageIndex,
    required String rectsJson,
    this.textSnapshot = const Value.absent(),
    this.note = const Value.absent(),
    required int color,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageIndex = Value(pageIndex),
       rectsJson = Value(rectsJson),
       color = Value(color),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HighlightRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageIndex,
    Expression<String>? rectsJson,
    Expression<String>? textSnapshot,
    Expression<String>? note,
    Expression<int>? color,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageIndex != null) 'page_index': pageIndex,
      if (rectsJson != null) 'rects_json': rectsJson,
      if (textSnapshot != null) 'text_snapshot': textSnapshot,
      if (note != null) 'note': note,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HighlightsCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageIndex,
    Value<String>? rectsJson,
    Value<String?>? textSnapshot,
    Value<String?>? note,
    Value<int>? color,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageIndex: pageIndex ?? this.pageIndex,
      rectsJson: rectsJson ?? this.rectsJson,
      textSnapshot: textSnapshot ?? this.textSnapshot,
      note: note ?? this.note,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (rectsJson.present) {
      map['rects_json'] = Variable<String>(rectsJson.value);
    }
    if (textSnapshot.present) {
      map['text_snapshot'] = Variable<String>(textSnapshot.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('rectsJson: $rectsJson, ')
          ..write('textSnapshot: $textSnapshot, ')
          ..write('note: $note, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TocEntriesTable extends TocEntries
    with TableInfo<$TocEntriesTable, TocEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TocEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIndexMeta = const VerificationMeta(
    'pageIndex',
  );
  @override
  late final GeneratedColumn<int> pageIndex = GeneratedColumn<int>(
    'page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrefMeta = const VerificationMeta('href');
  @override
  late final GeneratedColumn<String> href = GeneratedColumn<String>(
    'href',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fragmentMeta = const VerificationMeta(
    'fragment',
  );
  @override
  late final GeneratedColumn<String> fragment = GeneratedColumn<String>(
    'fragment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    parentId,
    title,
    level,
    pageIndex,
    href,
    fragment,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'toc_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TocEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('page_index')) {
      context.handle(
        _pageIndexMeta,
        pageIndex.isAcceptableOrUnknown(data['page_index']!, _pageIndexMeta),
      );
    }
    if (data.containsKey('href')) {
      context.handle(
        _hrefMeta,
        href.isAcceptableOrUnknown(data['href']!, _hrefMeta),
      );
    }
    if (data.containsKey('fragment')) {
      context.handle(
        _fragmentMeta,
        fragment.isAcceptableOrUnknown(data['fragment']!, _fragmentMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TocEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TocEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      pageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_index'],
      ),
      href: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}href'],
      ),
      fragment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fragment'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TocEntriesTable createAlias(String alias) {
    return $TocEntriesTable(attachedDatabase, alias);
  }
}

class TocEntryRow extends DataClass implements Insertable<TocEntryRow> {
  final String id;
  final String documentId;
  final String? parentId;
  final String title;
  final int level;

  /// PDF 目标页（0 基）；EPUB 为 null。
  final int? pageIndex;

  /// EPUB 目标文件（相对 OPF 目录、已 URL 解码）；PDF 为 null。
  final String? href;

  /// EPUB 目标片段（`#` 之后）；无片段为 null。
  final String? fragment;
  final int sortOrder;
  const TocEntryRow({
    required this.id,
    required this.documentId,
    this.parentId,
    required this.title,
    required this.level,
    this.pageIndex,
    this.href,
    this.fragment,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['title'] = Variable<String>(title);
    map['level'] = Variable<int>(level);
    if (!nullToAbsent || pageIndex != null) {
      map['page_index'] = Variable<int>(pageIndex);
    }
    if (!nullToAbsent || href != null) {
      map['href'] = Variable<String>(href);
    }
    if (!nullToAbsent || fragment != null) {
      map['fragment'] = Variable<String>(fragment);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TocEntriesCompanion toCompanion(bool nullToAbsent) {
    return TocEntriesCompanion(
      id: Value(id),
      documentId: Value(documentId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      title: Value(title),
      level: Value(level),
      pageIndex: pageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pageIndex),
      href: href == null && nullToAbsent ? const Value.absent() : Value(href),
      fragment: fragment == null && nullToAbsent
          ? const Value.absent()
          : Value(fragment),
      sortOrder: Value(sortOrder),
    );
  }

  factory TocEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TocEntryRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      title: serializer.fromJson<String>(json['title']),
      level: serializer.fromJson<int>(json['level']),
      pageIndex: serializer.fromJson<int?>(json['pageIndex']),
      href: serializer.fromJson<String?>(json['href']),
      fragment: serializer.fromJson<String?>(json['fragment']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'parentId': serializer.toJson<String?>(parentId),
      'title': serializer.toJson<String>(title),
      'level': serializer.toJson<int>(level),
      'pageIndex': serializer.toJson<int?>(pageIndex),
      'href': serializer.toJson<String?>(href),
      'fragment': serializer.toJson<String?>(fragment),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TocEntryRow copyWith({
    String? id,
    String? documentId,
    Value<String?> parentId = const Value.absent(),
    String? title,
    int? level,
    Value<int?> pageIndex = const Value.absent(),
    Value<String?> href = const Value.absent(),
    Value<String?> fragment = const Value.absent(),
    int? sortOrder,
  }) => TocEntryRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    parentId: parentId.present ? parentId.value : this.parentId,
    title: title ?? this.title,
    level: level ?? this.level,
    pageIndex: pageIndex.present ? pageIndex.value : this.pageIndex,
    href: href.present ? href.value : this.href,
    fragment: fragment.present ? fragment.value : this.fragment,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TocEntryRow copyWithCompanion(TocEntriesCompanion data) {
    return TocEntryRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      title: data.title.present ? data.title.value : this.title,
      level: data.level.present ? data.level.value : this.level,
      pageIndex: data.pageIndex.present ? data.pageIndex.value : this.pageIndex,
      href: data.href.present ? data.href.value : this.href,
      fragment: data.fragment.present ? data.fragment.value : this.fragment,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TocEntryRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('level: $level, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('href: $href, ')
          ..write('fragment: $fragment, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    parentId,
    title,
    level,
    pageIndex,
    href,
    fragment,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TocEntryRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.parentId == this.parentId &&
          other.title == this.title &&
          other.level == this.level &&
          other.pageIndex == this.pageIndex &&
          other.href == this.href &&
          other.fragment == this.fragment &&
          other.sortOrder == this.sortOrder);
}

class TocEntriesCompanion extends UpdateCompanion<TocEntryRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<String?> parentId;
  final Value<String> title;
  final Value<int> level;
  final Value<int?> pageIndex;
  final Value<String?> href;
  final Value<String?> fragment;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TocEntriesCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.title = const Value.absent(),
    this.level = const Value.absent(),
    this.pageIndex = const Value.absent(),
    this.href = const Value.absent(),
    this.fragment = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TocEntriesCompanion.insert({
    required String id,
    required String documentId,
    this.parentId = const Value.absent(),
    required String title,
    required int level,
    this.pageIndex = const Value.absent(),
    this.href = const Value.absent(),
    this.fragment = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       title = Value(title),
       level = Value(level),
       sortOrder = Value(sortOrder);
  static Insertable<TocEntryRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<String>? parentId,
    Expression<String>? title,
    Expression<int>? level,
    Expression<int>? pageIndex,
    Expression<String>? href,
    Expression<String>? fragment,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (parentId != null) 'parent_id': parentId,
      if (title != null) 'title': title,
      if (level != null) 'level': level,
      if (pageIndex != null) 'page_index': pageIndex,
      if (href != null) 'href': href,
      if (fragment != null) 'fragment': fragment,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TocEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<String?>? parentId,
    Value<String>? title,
    Value<int>? level,
    Value<int?>? pageIndex,
    Value<String?>? href,
    Value<String?>? fragment,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return TocEntriesCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      level: level ?? this.level,
      pageIndex: pageIndex ?? this.pageIndex,
      href: href ?? this.href,
      fragment: fragment ?? this.fragment,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (pageIndex.present) {
      map['page_index'] = Variable<int>(pageIndex.value);
    }
    if (href.present) {
      map['href'] = Variable<String>(href.value);
    }
    if (fragment.present) {
      map['fragment'] = Variable<String>(fragment.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TocEntriesCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('level: $level, ')
          ..write('pageIndex: $pageIndex, ')
          ..write('href: $href, ')
          ..write('fragment: $fragment, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $TocEntriesTable tocEntries = $TocEntriesTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final DocumentsDao documentsDao = DocumentsDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  late final BookmarksDao bookmarksDao = BookmarksDao(this as AppDatabase);
  late final TocDao tocDao = TocDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    readingProgress,
    bookmarks,
    highlights,
    tocEntries,
    appMeta,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_progress', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('highlights', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('toc_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String sha256,
      required String title,
      Value<String?> author,
      Value<String> format,
      required String relPath,
      Value<String?> coverRelPath,
      Value<int?> pageCount,
      required int fileSize,
      required bool hasTextLayer,
      required int addedAt,
      Value<int?> lastOpenedAt,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> sha256,
      Value<String> title,
      Value<String?> author,
      Value<String> format,
      Value<String> relPath,
      Value<String?> coverRelPath,
      Value<int?> pageCount,
      Value<int> fileSize,
      Value<bool> hasTextLayer,
      Value<int> addedAt,
      Value<int?> lastOpenedAt,
      Value<int> rowid,
    });

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReadingProgressTable, List<ReadingProgressRow>>
  _readingProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingProgress,
    aliasName: 'documents__id__reading_progress__document_id',
  );

  $$ReadingProgressTableProcessedTableManager get readingProgressRefs {
    final manager = $$ReadingProgressTableTableManager(
      $_db,
      $_db.readingProgress,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<BookmarkRow>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'documents__id__bookmarks__document_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HighlightsTable, List<HighlightRow>>
  _highlightsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.highlights,
    aliasName: 'documents__id__highlights__document_id',
  );

  $$HighlightsTableProcessedTableManager get highlightsRefs {
    final manager = $$HighlightsTableTableManager(
      $_db,
      $_db.highlights,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_highlightsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TocEntriesTable, List<TocEntryRow>>
  _tocEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.tocEntries,
    aliasName: 'documents__id__toc_entries__document_id',
  );

  $$TocEntriesTableProcessedTableManager get tocEntriesRefs {
    final manager = $$TocEntriesTableTableManager(
      $_db,
      $_db.tocEntries,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tocEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverRelPath => $composableBuilder(
    column: $table.coverRelPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingProgressRefs(
    Expression<bool> Function($$ReadingProgressTableFilterComposer f) f,
  ) {
    final $$ReadingProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableFilterComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> highlightsRefs(
    Expression<bool> Function($$HighlightsTableFilterComposer f) f,
  ) {
    final $$HighlightsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.highlights,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HighlightsTableFilterComposer(
            $db: $db,
            $table: $db.highlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tocEntriesRefs(
    Expression<bool> Function($$TocEntriesTableFilterComposer f) f,
  ) {
    final $$TocEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tocEntries,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TocEntriesTableFilterComposer(
            $db: $db,
            $table: $db.tocEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverRelPath => $composableBuilder(
    column: $table.coverRelPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get relPath =>
      $composableBuilder(column: $table.relPath, builder: (column) => column);

  GeneratedColumn<String> get coverRelPath => $composableBuilder(
    column: $table.coverRelPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<bool> get hasTextLayer => $composableBuilder(
    column: $table.hasTextLayer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  Expression<T> readingProgressRefs<T extends Object>(
    Expression<T> Function($$ReadingProgressTableAnnotationComposer a) f,
  ) {
    final $$ReadingProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingProgress,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.readingProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> highlightsRefs<T extends Object>(
    Expression<T> Function($$HighlightsTableAnnotationComposer a) f,
  ) {
    final $$HighlightsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.highlights,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HighlightsTableAnnotationComposer(
            $db: $db,
            $table: $db.highlights,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tocEntriesRefs<T extends Object>(
    Expression<T> Function($$TocEntriesTableAnnotationComposer a) f,
  ) {
    final $$TocEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tocEntries,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TocEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.tocEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (DocumentRow, $$DocumentsTableReferences),
          DocumentRow,
          PrefetchHooks Function({
            bool readingProgressRefs,
            bool bookmarksRefs,
            bool highlightsRefs,
            bool tocEntriesRefs,
          })
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> relPath = const Value.absent(),
                Value<String?> coverRelPath = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<bool> hasTextLayer = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                sha256: sha256,
                title: title,
                author: author,
                format: format,
                relPath: relPath,
                coverRelPath: coverRelPath,
                pageCount: pageCount,
                fileSize: fileSize,
                hasTextLayer: hasTextLayer,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sha256,
                required String title,
                Value<String?> author = const Value.absent(),
                Value<String> format = const Value.absent(),
                required String relPath,
                Value<String?> coverRelPath = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                required int fileSize,
                required bool hasTextLayer,
                required int addedAt,
                Value<int?> lastOpenedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                sha256: sha256,
                title: title,
                author: author,
                format: format,
                relPath: relPath,
                coverRelPath: coverRelPath,
                pageCount: pageCount,
                fileSize: fileSize,
                hasTextLayer: hasTextLayer,
                addedAt: addedAt,
                lastOpenedAt: lastOpenedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentsTable, DocumentRow>(table),
                  $$DocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                readingProgressRefs = false,
                bookmarksRefs = false,
                highlightsRefs = false,
                tocEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (readingProgressRefs) db.readingProgress,
                    if (bookmarksRefs) db.bookmarks,
                    if (highlightsRefs) db.highlights,
                    if (tocEntriesRefs) db.tocEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (readingProgressRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          ReadingProgressRow,
                          $ReadingProgressTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._readingProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).readingProgressRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          BookmarkRow,
                          $BookmarksTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (highlightsRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          HighlightRow,
                          $HighlightsTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._highlightsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).highlightsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (tocEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          DocumentRow,
                          $DocumentsTable,
                          TocEntryRow,
                          $TocEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$DocumentsTableReferences
                              ._tocEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).tocEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (DocumentRow, $$DocumentsTableReferences),
      DocumentRow,
      PrefetchHooks Function({
        bool readingProgressRefs,
        bool bookmarksRefs,
        bool highlightsRefs,
        bool tocEntriesRefs,
      })
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      required String documentId,
      Value<int?> pageIndex,
      Value<double?> position,
      Value<double> offsetY,
      Value<double?> zoom,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<String> documentId,
      Value<int?> pageIndex,
      Value<double?> position,
      Value<double> offsetY,
      Value<double?> zoom,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$ReadingProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressRow
        > {
  $$ReadingProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('reading_progress__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get offsetY => $composableBuilder(
    column: $table.offsetY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get offsetY =>
      $composableBuilder(column: $table.offsetY, builder: (column) => column);

  GeneratedColumn<double> get zoom =>
      $composableBuilder(column: $table.zoom, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressRow,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (ReadingProgressRow, $$ReadingProgressTableReferences),
          ReadingProgressRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$ReadingProgressTableTableManager(
    _$AppDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<double?> position = const Value.absent(),
                Value<double> offsetY = const Value.absent(),
                Value<double?> zoom = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                documentId: documentId,
                pageIndex: pageIndex,
                position: position,
                offsetY: offsetY,
                zoom: zoom,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                Value<int?> pageIndex = const Value.absent(),
                Value<double?> position = const Value.absent(),
                Value<double> offsetY = const Value.absent(),
                Value<double?> zoom = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                documentId: documentId,
                pageIndex: pageIndex,
                position: position,
                offsetY: offsetY,
                zoom: zoom,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingProgressTable, ReadingProgressRow>(table),
                  $$ReadingProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable:
                                    $$ReadingProgressTableReferences
                                        ._documentIdTable(db),
                                referencedColumn:
                                    $$ReadingProgressTableReferences
                                        ._documentIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressTable,
      ReadingProgressRow,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (ReadingProgressRow, $$ReadingProgressTableReferences),
      ReadingProgressRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String documentId,
      Value<int?> pageIndex,
      Value<double?> position,
      required double posY,
      required String label,
      Value<String?> excerpt,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int?> pageIndex,
      Value<double?> position,
      Value<double> posY,
      Value<String> label,
      Value<String?> excerpt,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('bookmarks__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<double> get posY =>
      $composableBuilder(column: $table.posY, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (BookmarkRow, $$BookmarksTableReferences),
          BookmarkRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<double?> position = const Value.absent(),
                Value<double> posY = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> excerpt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                documentId: documentId,
                pageIndex: pageIndex,
                position: position,
                posY: posY,
                label: label,
                excerpt: excerpt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                Value<int?> pageIndex = const Value.absent(),
                Value<double?> position = const Value.absent(),
                required double posY,
                required String label,
                Value<String?> excerpt = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                documentId: documentId,
                pageIndex: pageIndex,
                position: position,
                posY: posY,
                label: label,
                excerpt: excerpt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, BookmarkRow>(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$BookmarksTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$BookmarksTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (BookmarkRow, $$BookmarksTableReferences),
      BookmarkRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$HighlightsTableCreateCompanionBuilder =
    HighlightsCompanion Function({
      required String id,
      required String documentId,
      required int pageIndex,
      required String rectsJson,
      Value<String?> textSnapshot,
      Value<String?> note,
      required int color,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$HighlightsTableUpdateCompanionBuilder =
    HighlightsCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageIndex,
      Value<String> rectsJson,
      Value<String?> textSnapshot,
      Value<String?> note,
      Value<int> color,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$HighlightsTableReferences
    extends BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow> {
  $$HighlightsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('highlights__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rectsJson => $composableBuilder(
    column: $table.rectsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textSnapshot => $composableBuilder(
    column: $table.textSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rectsJson => $composableBuilder(
    column: $table.rectsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textSnapshot => $composableBuilder(
    column: $table.textSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get rectsJson =>
      $composableBuilder(column: $table.rectsJson, builder: (column) => column);

  GeneratedColumn<String> get textSnapshot => $composableBuilder(
    column: $table.textSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HighlightsTable,
          HighlightRow,
          $$HighlightsTableFilterComposer,
          $$HighlightsTableOrderingComposer,
          $$HighlightsTableAnnotationComposer,
          $$HighlightsTableCreateCompanionBuilder,
          $$HighlightsTableUpdateCompanionBuilder,
          (HighlightRow, $$HighlightsTableReferences),
          HighlightRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$HighlightsTableTableManager(_$AppDatabase db, $HighlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageIndex = const Value.absent(),
                Value<String> rectsJson = const Value.absent(),
                Value<String?> textSnapshot = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion(
                id: id,
                documentId: documentId,
                pageIndex: pageIndex,
                rectsJson: rectsJson,
                textSnapshot: textSnapshot,
                note: note,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageIndex,
                required String rectsJson,
                Value<String?> textSnapshot = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int color,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion.insert(
                id: id,
                documentId: documentId,
                pageIndex: pageIndex,
                rectsJson: rectsJson,
                textSnapshot: textSnapshot,
                note: note,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HighlightsTable, HighlightRow>(table),
                  $$HighlightsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$HighlightsTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$HighlightsTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HighlightsTable,
      HighlightRow,
      $$HighlightsTableFilterComposer,
      $$HighlightsTableOrderingComposer,
      $$HighlightsTableAnnotationComposer,
      $$HighlightsTableCreateCompanionBuilder,
      $$HighlightsTableUpdateCompanionBuilder,
      (HighlightRow, $$HighlightsTableReferences),
      HighlightRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$TocEntriesTableCreateCompanionBuilder =
    TocEntriesCompanion Function({
      required String id,
      required String documentId,
      Value<String?> parentId,
      required String title,
      required int level,
      Value<int?> pageIndex,
      Value<String?> href,
      Value<String?> fragment,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$TocEntriesTableUpdateCompanionBuilder =
    TocEntriesCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<String?> parentId,
      Value<String> title,
      Value<int> level,
      Value<int?> pageIndex,
      Value<String?> href,
      Value<String?> fragment,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$TocEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $TocEntriesTable, TocEntryRow> {
  $$TocEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.documents.createAlias('toc_entries__document_id__documents__id');

  $$DocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$DocumentsTableTableManager(
      $_db,
      $_db.documents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TocEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fragment => $composableBuilder(
    column: $table.fragment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$DocumentsTableFilterComposer get documentId {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableFilterComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TocEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageIndex => $composableBuilder(
    column: $table.pageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get href => $composableBuilder(
    column: $table.href,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fragment => $composableBuilder(
    column: $table.fragment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$DocumentsTableOrderingComposer get documentId {
    final $$DocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TocEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TocEntriesTable> {
  $$TocEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get pageIndex =>
      $composableBuilder(column: $table.pageIndex, builder: (column) => column);

  GeneratedColumn<String> get href =>
      $composableBuilder(column: $table.href, builder: (column) => column);

  GeneratedColumn<String> get fragment =>
      $composableBuilder(column: $table.fragment, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$DocumentsTableAnnotationComposer get documentId {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.documents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.documents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TocEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TocEntriesTable,
          TocEntryRow,
          $$TocEntriesTableFilterComposer,
          $$TocEntriesTableOrderingComposer,
          $$TocEntriesTableAnnotationComposer,
          $$TocEntriesTableCreateCompanionBuilder,
          $$TocEntriesTableUpdateCompanionBuilder,
          (TocEntryRow, $$TocEntriesTableReferences),
          TocEntryRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$TocEntriesTableTableManager(_$AppDatabase db, $TocEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TocEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TocEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TocEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int?> pageIndex = const Value.absent(),
                Value<String?> href = const Value.absent(),
                Value<String?> fragment = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TocEntriesCompanion(
                id: id,
                documentId: documentId,
                parentId: parentId,
                title: title,
                level: level,
                pageIndex: pageIndex,
                href: href,
                fragment: fragment,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                Value<String?> parentId = const Value.absent(),
                required String title,
                required int level,
                Value<int?> pageIndex = const Value.absent(),
                Value<String?> href = const Value.absent(),
                Value<String?> fragment = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => TocEntriesCompanion.insert(
                id: id,
                documentId: documentId,
                parentId: parentId,
                title: title,
                level: level,
                pageIndex: pageIndex,
                href: href,
                fragment: fragment,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TocEntriesTable, TocEntryRow>(table),
                  $$TocEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentId,
                                referencedTable: $$TocEntriesTableReferences
                                    ._documentIdTable(db),
                                referencedColumn: $$TocEntriesTableReferences
                                    ._documentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TocEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TocEntriesTable,
      TocEntryRow,
      $$TocEntriesTableFilterComposer,
      $$TocEntriesTableOrderingComposer,
      $$TocEntriesTableAnnotationComposer,
      $$TocEntriesTableCreateCompanionBuilder,
      $$TocEntriesTableUpdateCompanionBuilder,
      (TocEntryRow, $$TocEntriesTableReferences),
      TocEntryRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTable, AppMetaRow>(table),
                  BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$HighlightsTableTableManager get highlights =>
      $$HighlightsTableTableManager(_db, _db.highlights);
  $$TocEntriesTableTableManager get tocEntries =>
      $$TocEntriesTableTableManager(_db, _db.tocEntries);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
