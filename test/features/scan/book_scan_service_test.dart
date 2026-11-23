import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/core/ebook/book_format.dart';
import 'package:home_pdf_reader/features/scan/application/book_scan_service.dart';

void main() {
  group('formatOfFileName', () {
    test('只接受 PDF 与 EPUB，大小写不敏感', () {
      expect(formatOfFileName('a.pdf'), BookFormat.pdf);
      expect(formatOfFileName('A.PDF'), BookFormat.pdf);
      expect(formatOfFileName('book.epub'), BookFormat.epub);
      expect(formatOfFileName('book.EPUB'), BookFormat.epub);
      expect(formatOfFileName('book.mobi'), isNull);
      expect(formatOfFileName('book.azw3'), isNull);
      expect(formatOfFileName('notes.txt'), isNull);
      expect(formatOfFileName('pdf'), isNull);
    });
  });

  group('BookScanService', () {
    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('book_scan_test_');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    test('同时识别 PDF / EPUB，排除其它格式并标记损坏文件', () async {
      final pdfBytes = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
      final epubBytes = Uint8List.fromList(<int>[
        0x50, 0x4B, 0x03, 0x04, // ZIP 本地文件头
        0x00, 0x00, 0x00, 0x00,
      ]);
      await File('${temp.path}${Platform.pathSeparator}good.pdf')
          .writeAsBytes(pdfBytes);
      await File('${temp.path}${Platform.pathSeparator}BOOK.EPUB')
          .writeAsBytes(epubBytes);
      await File('${temp.path}${Platform.pathSeparator}broken.pdf')
          .writeAsString('not a pdf');
      await File('${temp.path}${Platform.pathSeparator}fake.epub')
          .writeAsString('not a zip');
      await File('${temp.path}${Platform.pathSeparator}notes.txt')
          .writeAsString('ignore me');
      final nested = Directory('${temp.path}${Platform.pathSeparator}sub');
      await nested.create();
      await File('${nested.path}${Platform.pathSeparator}nested.epub')
          .writeAsBytes(epubBytes);

      final events = await BookScanService().scan(roots: <String>[temp.path]).toList();
      final done = events.whereType<ScanDoneEvent>().single;

      expect(
        done.files.map((f) => f.name).toSet(),
        <String>{'good.pdf', 'BOOK.EPUB', 'broken.pdf', 'fake.epub', 'nested.epub'},
      );
      expect(
        done.files.firstWhere((f) => f.name == 'good.pdf').format,
        BookFormat.pdf,
      );
      expect(
        done.files.firstWhere((f) => f.name == 'BOOK.EPUB').format,
        BookFormat.epub,
      );
      expect(
        done.files.firstWhere((f) => f.name == 'broken.pdf').looksBroken,
        isTrue,
      );
      expect(
        done.files.firstWhere((f) => f.name == 'fake.epub').looksBroken,
        isTrue,
      );
      expect(
        done.files.firstWhere((f) => f.name == 'nested.epub').looksBroken,
        isFalse,
      );
    });
  });
}
