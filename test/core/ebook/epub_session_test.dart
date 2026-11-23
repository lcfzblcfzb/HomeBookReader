import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/epub_session.dart';

void main() {
  test('EpubSession 读取 spine、正文与章内资源', () {
    final session = EpubSession.openBytes(Uint8List.fromList(_buildEpub()));

    expect(session.chapterCount, 2);
    expect(session.spine[0].href, 'OEBPS/text/ch1.xhtml');
    expect(session.spine[1].href, 'OEBPS/text/ch2.xhtml');
    expect(session.readChapter(0), contains('第一章正文'));
    expect(session.readChapter(1), contains('第二章正文'));
    expect(session.readChapter(2), isNull);

    expect(
      session.resolveInChapter('OEBPS/text/ch1.xhtml', '../images/pic.png'),
      'OEBPS/images/pic.png',
    );
    expect(session.readResource('OEBPS/images/pic.png'), isNotNull);

    // 目录 href 相对 OPF 目录；spine 是包内完整路径，两种都要能定位。
    expect(session.spineIndexForHref('text/ch1.xhtml'), 0);
    expect(session.spineIndexForHref('OEBPS/text/ch2.xhtml'), 1);
    expect(session.spineIndexForHref('text/missing.xhtml'), isNull);
  });

  test('EpubSession 缺正文的 EPUB 被拒绝', () {
    expect(
      () => EpubSession.openBytes(Uint8List.fromList(_buildEpub(emptySpine: true))),
      throwsA(isA<Exception>()),
    );
  });
}

List<int> _buildEpub({bool emptySpine = false}) {
  final archive = Archive();
  void add(String name, String content) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  }

  add('mimetype', 'application/epub+zip');
  add('META-INF/container.xml', '''
<?xml version="1.0" encoding="utf-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>
''');
  add('OEBPS/content.opf', '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>会话测试</dc:title></metadata>
  <manifest>
    ${emptySpine ? '' : '<item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>'}
    ${emptySpine ? '' : '<item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>'}
    <item id="pic" href="images/pic.png" media-type="image/png"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
  </manifest>
  <spine>
    ${emptySpine ? '' : '<itemref idref="ch1"/><itemref idref="ch2"/>'}
  </spine>
</package>
''');
  add('OEBPS/text/ch1.xhtml', '<html><body><h1>第一章</h1><p>第一章正文</p></body></html>');
  add('OEBPS/text/ch2.xhtml', '<html><body><h1>第二章</h1><p>第二章正文</p></body></html>');
  add('OEBPS/images/pic.png', 'fake-png');
  return ZipEncoder().encode(archive);
}
