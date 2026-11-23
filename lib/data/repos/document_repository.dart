import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/ebook/book_format.dart';
import '../../core/ebook/epub_models.dart';
import '../../core/ebook/epub_parser.dart';
import '../../core/pdf/pdf_engine.dart';
import '../../core/pdf/pdf_models.dart';
import '../../core/storage/app_paths.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/hashing.dart';
import '../db/app_database.dart';

/// 文件已丢失（被外部删除/移动）。
class DocumentMissingException implements Exception {
  const DocumentMissingException(this.documentId);

  final String documentId;

  @override
  String toString() => 'DocumentMissingException($documentId)';
}

/// 导入结果。
sealed class ImportOutcome {
  const ImportOutcome();
}

class ImportSuccess extends ImportOutcome {
  const ImportSuccess(this.document);

  final DocumentRow document;
}

class ImportDuplicate extends ImportOutcome {
  const ImportDuplicate(this.document);

  final DocumentRow document;
}

class ImportInvalid extends ImportOutcome {
  const ImportInvalid(this.reason);

  /// 面向用户的中文原因。
  final String reason;
}

/// 文档库仓库：导入、列表、打开句柄、删除。
class DocumentRepository {
  DocumentRepository({required AppDatabase database, required PdfEngine engine})
      : _db = database,
        _engine = engine;

  final AppDatabase _db;
  final PdfEngine _engine;
  final Uuid _uuid = const Uuid();

  Stream<List<DocumentRow>> watchLibrary() => _db.documentsDao.watchAll();

  Future<List<DocumentRow>> list() => _db.documentsDao.listAll();

  Future<DocumentRow?> byId(String id) => _db.documentsDao.byId(id);

  /// 打开文档句柄并刷新最近打开时间。文件缺失抛 [DocumentMissingException]。
  Future<PdfDocumentHandle> openHandle(DocumentRow document) async {
    final file = AppPaths.resolve(document.relPath);
    if (!await file.exists()) {
      throw DocumentMissingException(document.id);
    }
    final handle = await _engine.open(file.path);
    await _db.documentsDao.touchOpened(document.id, DateTime.now().millisecondsSinceEpoch);
    return handle;
  }

  /// 导入单个文件：格式分流 → 校验 → 去重 → 解析 → 复制 → 封面 → 入库。
  Future<ImportOutcome> importFile(File source) async {
    if (!await source.exists()) {
      return const ImportInvalid('文件不存在或无法访问');
    }
    final format = formatOfFileName(source.path);
    if (format == null) {
      return const ImportInvalid('仅支持 PDF 与 EPUB 文件');
    }
    if (format == BookFormat.pdf && !await _hasPdfHeader(source)) {
      return const ImportInvalid('文件不是有效的 PDF（文件头校验失败）');
    }

    AppLogger.log('导入：计算哈希', tag: 'IMPORT', detail: source.path);
    final hash = await sha256OfFile(source);
    final existing = await _db.documentsDao.bySha256(hash);
    if (existing != null) {
      return ImportDuplicate(existing);
    }

    return switch (format) {
      BookFormat.pdf => _importPdf(source, hash),
      BookFormat.epub => _importEpub(source, hash),
    };
  }

  /// EPUB：ZIP + mimetype 校验、OPF 元数据、封面、nav / ncx 目录。
  Future<ImportOutcome> _importEpub(File source, String hash) async {
    final EpubBook book;
    try {
      book = EpubParser.parse(await source.readAsBytes());
    } on EpubInvalidException catch (e) {
      AppLogger.log('EPUB 校验失败', level: 'WARN', tag: 'IMPORT', detail: '${source.path}：${e.reason}');
      return ImportInvalid(e.reason);
    } catch (e) {
      AppLogger.log('EPUB 解析失败', level: 'WARN', tag: 'IMPORT', detail: '${source.path}：$e');
      return ImportInvalid('EPUB 解析失败：$e');
    }

    try {
      final id = _uuid.v4();
      final target = File('${AppPaths.epubsDir.path}${Platform.pathSeparator}$id.epub');
      await source.copy(target.path);

      String? coverRelPath;
      try {
        coverRelPath = await _writeEpubCover(book, id);
      } catch (_) {
        // 封面失败不阻断导入，书架显示占位。
      }

      final stat = await target.stat();
      final title = book.title.trim();
      final author = book.author?.trim();
      final document = DocumentsCompanion.insert(
        id: id,
        sha256: hash,
        title: title.isEmpty ? _titleOf(source) : title,
        author: Value(author == null || author.isEmpty ? null : author),
        format: Value(BookFormat.epub.name),
        relPath: AppPaths.toRelative(target.path),
        coverRelPath: Value(coverRelPath),
        pageCount: const Value<int?>(null),
        fileSize: stat.size,
        hasTextLayer: true,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.documentsDao.insertDocument(document);
      await _saveEpubToc(id, book.toc);
      final row = await _db.documentsDao.byId(id);
      if (row == null) {
        return const ImportInvalid('写入文档库失败');
      }
      AppLogger.log(
        '导入：EPUB 完成',
        tag: 'IMPORT',
        detail: 'id=$id toc=${book.toc.length} cover=${coverRelPath ?? "无"}',
      );
      return ImportSuccess(row);
    } catch (e) {
      return ImportInvalid('导入 EPUB 失败：$e');
    }
  }

  Future<ImportOutcome> _importPdf(File source, String hash) async {
    PdfDocumentHandle? handle;
    try {
      AppLogger.log('导入：打开 PDF', tag: 'IMPORT', detail: 'sha256=$hash');
      handle = await _engine.open(source.path);
      final pageCount = handle.pageCount;
      AppLogger.log('导入：PDF 已打开，页数 $pageCount', tag: 'IMPORT');
      // 原生层（PDFium）在坏文件上可能直接崩溃；打点以便事后从日志定位阶段。
      final hasTextLayer = await handle.hasTextLayer();
      AppLogger.log('导入：文字层探测完成 textLayer=$hasTextLayer', tag: 'IMPORT');

      final id = _uuid.v4();
      final target = File('${AppPaths.pdfsDir.path}${Platform.pathSeparator}$id.pdf');
      await source.copy(target.path);
      AppLogger.log('导入：文件已复制', tag: 'IMPORT', detail: target.path);

      String? coverRelPath;
      try {
        coverRelPath = await _writeCover(handle, id);
      } catch (_) {
        // 封面失败不阻断导入，书架显示占位。
      }
      AppLogger.log('导入：封面完成 ${coverRelPath ?? "无"}', tag: 'IMPORT');

      final stat = await target.stat();
      final document = DocumentsCompanion.insert(
        id: id,
        sha256: hash,
        title: _titleOf(source),
        relPath: AppPaths.toRelative(target.path),
        coverRelPath: Value(coverRelPath),
        pageCount: Value(pageCount),
        fileSize: stat.size,
        hasTextLayer: hasTextLayer,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _db.documentsDao.insertDocument(document);
      final row = await _db.documentsDao.byId(id);
      if (row == null) {
        return const ImportInvalid('写入文档库失败');
      }
      return ImportSuccess(row);
    } on PdfOpenException catch (e) {
      return ImportInvalid(_describe(e));
    } catch (e) {
      return ImportInvalid('导入失败：$e');
    } finally {
      await handle?.dispose();
    }
  }

  /// EPUB 目录在导入时一次解析落库，阅读页后续直接读缓存。
  Future<void> _saveEpubToc(String documentId, List<EpubTocEntry> toc) async {
    final ids = List<String>.generate(toc.length, (_) => _uuid.v4());
    final entries = <TocEntriesCompanion>[];
    for (var i = 0; i < toc.length; i++) {
      final node = toc[i];
      entries.add(
        TocEntriesCompanion.insert(
          id: ids[i],
          documentId: documentId,
          parentId: Value(
            node.parentIndex == null ? null : ids[node.parentIndex!],
          ),
          title: node.title,
          level: node.level,
          pageIndex: const Value<int?>(null),
          href: Value(node.href),
          fragment: Value(node.fragment),
          sortOrder: i,
        ),
      );
    }
    await _db.tocDao.replaceAll(documentId, entries);
  }

  Future<String?> _writeEpubCover(EpubBook book, String documentId) async {
    final bytes = book.coverBytes;
    if (bytes == null || bytes.isEmpty) return null;
    final extension = book.coverExtension ?? '.img';
    final file = File(
      '${AppPaths.coversDir.path}${Platform.pathSeparator}$documentId$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return AppPaths.toRelative(file.path);
  }

  /// 删除文档：先删库（级联），再删文件；文件删除失败只忽略。
  Future<void> delete(String documentId) async {
    final document = await _db.documentsDao.byId(documentId);
    if (document == null) return;
    await _db.documentsDao.deleteById(documentId);
    await _deleteQuietly(AppPaths.resolve(document.relPath));
    final cover = document.coverRelPath;
    if (cover != null) {
      await _deleteQuietly(AppPaths.resolve(cover));
    }
  }

  Future<bool> _hasPdfHeader(File file) async {
    final raf = await file.open();
    try {
      final bytes = await raf.read(5);
      return String.fromCharCodes(bytes) == '%PDF-';
    } finally {
      await raf.close();
    }
  }

  String _titleOf(File file) {
    final name = file.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  String _describe(PdfOpenException e) => switch (e.kind) {
        PdfFailureKind.encrypted => '该 PDF 已加密，本期不支持打开',
        PdfFailureKind.corrupted => '文件已损坏，无法解析',
        PdfFailureKind.unsupported => '该 PDF 使用了不支持的格式特性',
        PdfFailureKind.unknown => '无法打开该 PDF：${e.message}',
      };

  /// 生成首页封面（PNG，宽 300px），返回相对路径。
  Future<String> _writeCover(PdfDocumentHandle handle, String documentId) async {
    final image = await handle.renderPage(0, pixelWidth: 300);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('封面编码失败');
      final file = File('${AppPaths.coversDir.path}${Platform.pathSeparator}$documentId.png');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return AppPaths.toRelative(file.path);
    } finally {
      image.dispose();
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 只记日志级别忽略：下次启动做孤儿清理。
    }
  }
}
