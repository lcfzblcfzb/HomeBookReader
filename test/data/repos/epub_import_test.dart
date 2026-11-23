import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/pdf/pdf_engine.dart';
import 'package:home_pdf_reader/core/storage/app_paths.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/data/repos/document_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory temp;
  late AppDatabase db;
  late DocumentRepository repository;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('epub_import_test_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    await AppPaths.init();
    db = AppDatabase(NativeDatabase.memory());
    repository = DocumentRepository(database: db, engine: _UnusedPdfEngine());
  });

  tearDown(() async {
    await db.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('导入 EPUB：书名、作者、封面落盘，目录写 href + fragment', () async {
    final source = File('${temp.path}${Platform.pathSeparator}shelf.epub');
    await source.writeAsBytes(_buildEpub());

    final outcome = await repository.importFile(source);

    expect(outcome, isA<ImportSuccess>());
    final document = (outcome as ImportSuccess).document;
    expect(document.format, 'epub');
    expect(document.title, '书架样书');
    expect(document.author, '作者丙');
    expect(document.pageCount, isNull);
    expect(document.coverRelPath, isNotNull);
    expect(
      AppPaths.resolve(document.relPath).existsSync(),
      isTrue,
      reason: 'epub 应复制到应用私有目录',
    );
    expect(
      AppPaths.resolve(document.coverRelPath!).existsSync(),
      isTrue,
      reason: '封面应写入 covers 目录',
    );

    final toc = await db.tocDao.listByDocument(document.id);
    expect(toc.length, 2);
    expect(toc[0].title, '第一章');
    expect(toc[0].href, 'text/ch1.xhtml');
    expect(toc[0].fragment, 's1');
    expect(toc[0].pageIndex, isNull, reason: 'EPUB 不能占用页码字段');
    expect(toc[1].parentId, toc[0].id);
  });

  test('伪装 EPUB（mimetype 不对）被拒收，不写入书架', () async {
    final source = File('${temp.path}${Platform.pathSeparator}fake.epub');
    await source.writeAsBytes(
      _buildEpub(mimetype: 'application/zip'),
    );

    final outcome = await repository.importFile(source);

    expect(outcome, isA<ImportInvalid>());
    expect((outcome as ImportInvalid).reason, contains('mimetype'));
    expect(await db.documentsDao.listAll(), isEmpty);
  });

  test('重复导入同一 EPUB 返回 ImportDuplicate', () async {
    final source = File('${temp.path}${Platform.pathSeparator}shelf.epub');
    await source.writeAsBytes(_buildEpub());
    expect(await repository.importFile(source), isA<ImportSuccess>());

    final again = await repository.importFile(source);

    expect(again, isA<ImportDuplicate>());
    expect((await db.documentsDao.listAll()).length, 1);
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _UnusedPdfEngine implements PdfEngine {
  @override
  Future<PdfDocumentHandle> open(String absolutePath) =>
      throw UnsupportedError('本测试不打开 PDF');
}

List<int> _buildEpub({String mimetype = 'application/epub+zip'}) {
  final archive = Archive();
  void add(String name, String content) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  }

  add('mimetype', mimetype);
  add('META-INF/container.xml', '''
<?xml version="1.0" encoding="utf-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>
''');
  add('OEBPS/content.opf', '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>书架样书</dc:title>
    <dc:creator>作者丙</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="cover" href="images/cover.png" media-type="image/png" properties="cover-image"/>
  </manifest>
  <spine/>
</package>
''');
  add('OEBPS/nav.xhtml', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body><nav epub:type="toc"><ol>
    <li><a href="text/ch1.xhtml#s1">第一章</a>
      <ol><li><a href="text/ch1.xhtml#s1-1">第一节</a></li></ol>
    </li>
  </ol></nav></body>
</html>
''');
  add('OEBPS/images/cover.png', 'fake-png');
  return ZipEncoder().encode(archive);
}
