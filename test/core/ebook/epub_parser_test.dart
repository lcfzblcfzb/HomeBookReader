import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/epub_models.dart';
import 'package:home_pdf_reader/core/ebook/epub_parser.dart';

void main() {
  group('EpubParser', () {
    test('解析 EPUB3：元数据、cover-image、nav 目录与片段', () {
      final bytes = _buildEpub(<String, String>{
        'mimetype': 'application/epub+zip',
        'META-INF/container.xml': _containerXml('OEBPS/content.opf'),
        'OEBPS/content.opf': '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>测试之书</dc:title>
    <dc:creator>作者甲</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="cover" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>
    <item id="c1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine><itemref idref="c1"/></spine>
</package>
''',
        'OEBPS/nav.xhtml': '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="text/ch1.xhtml#sec1">第一章</a>
          <ol><li><a href="text/ch1.xhtml#sec1-1">第一节</a></li></ol>
        </li>
        <li><a href="text/chapter%201.xhtml">第二章</a></li>
      </ol>
    </nav>
  </body>
</html>
''',
        'OEBPS/images/cover.jpg': 'fake-jpeg',
      });

      final book = EpubParser.parse(bytes);

      expect(book.title, '测试之书');
      expect(book.author, '作者甲');
      expect(book.coverBytes, isNotNull);
      expect(book.coverExtension, '.jpg');
      expect(book.toc.length, 3);
      expect(book.toc[0].title, '第一章');
      expect(book.toc[0].level, 1);
      expect(book.toc[0].href, 'text/ch1.xhtml');
      expect(book.toc[0].fragment, 'sec1');
      expect(book.toc[1].level, 2);
      expect(book.toc[1].parentIndex, 0);
      expect(book.toc[2].href, 'text/chapter 1.xhtml');
      expect(book.toc[2].fragment, isNull);
    });

    test('解析 EPUB2：meta name=cover 与嵌套 ncx 目录', () {
      final bytes = _buildEpub(<String, String>{
        'mimetype': 'application/epub+zip',
        'META-INF/container.xml': _containerXml('OPS/book.opf'),
        'OPS/book.opf': '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>旧格式之书</dc:title>
    <dc:creator>作者乙</dc:creator>
    <meta name="cover" content="cover-img"/>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="cover-img" href="images/cover.png" media-type="image/png"/>
    <item id="c1" href="ch1.html" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx"><itemref idref="c1"/></spine>
</package>
''',
        'OPS/toc.ncx': '''
<?xml version="1.0" encoding="utf-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="n1">
      <navLabel><text>上部</text></navLabel>
      <content src="ch1.html#top"/>
      <navPoint id="n2">
        <navLabel><text>第一章</text></navLabel>
        <content src="ch1.html#c1"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>
''',
        'OPS/images/cover.png': 'fake-png',
      });

      final book = EpubParser.parse(bytes);

      expect(book.title, '旧格式之书');
      expect(book.author, '作者乙');
      expect(book.coverExtension, '.png');
      expect(book.toc.length, 2);
      expect(book.toc[0].title, '上部');
      expect(book.toc[0].fragment, 'top');
      expect(book.toc[1].title, '第一章');
      expect(book.toc[1].level, 2);
      expect(book.toc[1].parentIndex, 0);
    });

    test('封面缺失时不报错', () {
      final bytes = _buildEpub(<String, String>{
        'mimetype': 'application/epub+zip',
        'META-INF/container.xml': _containerXml('content.opf'),
        'content.opf': '''
<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>无封面</dc:title></metadata>
  <manifest/>
  <spine/>
</package>
''',
      });

      final book = EpubParser.parse(bytes);

      expect(book.title, '无封面');
      expect(book.coverBytes, isNull);
      expect(book.toc, isEmpty);
    });

    test('非 ZIP 文件被拒绝', () {
      expect(
        () => EpubParser.parse(utf8.encode('just text')),
        throwsA(
          isA<EpubInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('ZIP'),
          ),
        ),
      );
    });

    test('ZIP 缺少 mimetype 条目被拒绝', () {
      final bytes = _buildEpub(<String, String>{
        'META-INF/container.xml': _containerXml('content.opf'),
      });

      expect(
        () => EpubParser.parse(bytes),
        throwsA(
          isA<EpubInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('mimetype'),
          ),
        ),
      );
    });

    test('mimetype 内容不正确被拒绝', () {
      final bytes = _buildEpub(<String, String>{
        'mimetype': 'application/zip',
        'META-INF/container.xml': _containerXml('content.opf'),
      });

      expect(
        () => EpubParser.parse(bytes),
        throwsA(
          isA<EpubInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('mimetype'),
          ),
        ),
      );
    });

    test('缺少 container.xml 被拒绝', () {
      final bytes = _buildEpub(<String, String>{
        'mimetype': 'application/epub+zip',
      });

      expect(
        () => EpubParser.parse(bytes),
        throwsA(
          isA<EpubInvalidException>().having(
            (e) => e.reason,
            'reason',
            contains('container.xml'),
          ),
        ),
      );
    });
  });
}

String _containerXml(String opfPath) => '''
<?xml version="1.0" encoding="utf-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="$opfPath" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';

List<int> _buildEpub(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  });
  return ZipEncoder().encode(archive);
}
