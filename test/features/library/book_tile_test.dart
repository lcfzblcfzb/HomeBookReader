import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pdf_reader/data/db/app_database.dart';
import 'package:home_pdf_reader/features/library/widgets/book_tile.dart';

void main() {
  testWidgets('EPUB 条目显示书名、作者、位置与 EPUB 占位图标', (tester) async {
    final document = DocumentRow(
      id: 'e1',
      sha256: 'hash-e1',
      title: '书架样书',
      author: '作者丙',
      format: 'epub',
      relPath: 'epubs/e1.epub',
      pageCount: null,
      fileSize: 1024,
      hasTextLayer: true,
      addedAt: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookTile(
            document: document,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('书架样书'), findsOneWidget);
    expect(find.text('作者丙 · 位置 0%'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
  });

  testWidgets('PDF 条目保持页数与无文字层文案', (tester) async {
    final document = DocumentRow(
      id: 'p1',
      sha256: 'hash-p1',
      title: '扫描版 PDF',
      format: 'pdf',
      relPath: 'pdfs/p1.pdf',
      pageCount: 12,
      fileSize: 2048,
      hasTextLayer: false,
      addedAt: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookTile(
            document: document,
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('扫描版 PDF'), findsOneWidget);
    expect(find.text('12 页 · 无文字层'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });
}
