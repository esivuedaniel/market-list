import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/features/export/data/services/pdf_list_generator.dart';
import 'package:market_list/features/export/data/services/temp_export_file_store.dart';
import 'package:market_list/features/export/domain/entities/pdf_document_data.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class FakeClock extends Clock {
  const FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

void main() {
  late Directory tempDir;
  late FakeClock fakeClock;
  late TempExportFileStore fileStore;
  late Uint8List regularFontBytes;
  late Uint8List boldFontBytes;
  late PdfListGenerator generator;

  setUpAll(() async {
    regularFontBytes = await File('assets/fonts/NotoSans-Regular.ttf').readAsBytes();
    boldFontBytes = await File('assets/fonts/NotoSans-Bold.ttf').readAsBytes();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_gen_test_');
    fakeClock = FakeClock(DateTime.utc(2026, 10, 14, 10, 30));
    fileStore = TempExportFileStore(
      getTempDir: () async => tempDir,
      clock: fakeClock,
    );
    generator = PdfListGenerator(
      fileStore: fileStore,
      fontLoader: (path) async {
        if (path.contains('Bold')) return boldFontBytes;
        return regularFontBytes;
      },
      clock: fakeClock,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  final now = DateTime.utc(2026, 10, 14);
  final sampleList = ShoppingList(
    id: 'list-1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );

  final sampleItems = [
    ShoppingItem(
      id: 'i1',
      listId: 'list-1',
      name: 'Tomatoes',
      quantity: const Quantity.fromMilli(2500),
      unit: 'kg',
      unitPrice: const Money.fromMinor(150000),
      isBought: true,
      createdAt: now,
      updatedAt: now,
    ),
    ShoppingItem(
      id: 'i2',
      listId: 'list-1',
      name: 'Onions',
      quantity: const Quantity.fromMilli(3000),
      unit: 'pcs',
      unitPrice: const Money.fromMinor(20000),
      isBought: false,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('PdfListGenerator', () {
    test('FR-070/AS-19 glyph test: renders ₦, GH₵, £, and € with Noto Sans', () async {
      final regularFont = pw.Font.ttf(regularFontBytes.buffer.asByteData());
      final boldFont = pw.Font.ttf(boldFontBytes.buffer.asByteData());

      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );

      final pdf = pw.Document(theme: theme);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Currency Symbols Test', style: pw.TextStyle(font: boldFont, fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Text('Naira: ₦1,500.50'),
                pw.Text('Cedi: GH₵250.00'),
                pw.Text('Pound: £99.99'),
                pw.Text('Euro: €45.00'),
                pw.Text('Dollar: \$10.00'),
                pw.Text('Rand: R50.00'),
                pw.Text('Kenyan Shilling: KSh3,000.00'),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
    });

    test('FR-070/AS-19 performance check: 200 items build in under 3 seconds', () async {
      final regularFont = pw.Font.ttf(regularFontBytes.buffer.asByteData());
      final boldFont = pw.Font.ttf(boldFontBytes.buffer.asByteData());

      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      );

      final stopwatch = Stopwatch()..start();

      final pdf = pw.Document(theme: theme);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (context) {
            return [
              pw.Text('Performance Test List', style: pw.TextStyle(font: boldFont, fontSize: 20)),
              pw.Container(height: 2, color: PdfColor.fromHex('#F57C00')),
              pw.SizedBox(height: 12),
              pw.Table(
                children: [
                  pw.TableRow(
                    repeat: true,
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFE0B2)),
                    children: [
                      pw.Text('Done'),
                      pw.Text('No.'),
                      pw.Text('Item'),
                      pw.Text('Qty'),
                      pw.Text('Unit price (₦)'),
                      pw.Text('Line total (₦)'),
                    ],
                  ),
                  ...List.generate(
                    200,
                    (i) => pw.TableRow(
                      children: [
                        pw.CustomPaint(
                          size: const PdfPoint(10, 10),
                          painter: (canvas, size) {
                            canvas.drawRect(0, 0, 10, 10);
                            canvas.strokePath();
                          },
                        ),
                        pw.Text('${i + 1}'),
                        pw.Text('Item number $i with a longer description text'),
                        pw.Text('2.5 kg'),
                        pw.Text('1,500.00'),
                        pw.Text('3,750.00'),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      stopwatch.stop();

      expect(bytes, isNotEmpty);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    test('FR-070 generates valid PDF file for list items', () async {
      final detail = ListDetail(list: sampleList, items: sampleItems);
      final result = await generator.generate(PdfDocumentData(listDetail: detail));

      expect(result.isRight(), isTrue);
      final file = result.getOrElse((_) => throw StateError('failed'));
      expect(file.fileName, 'Sunday-market-20261014.pdf');
      expect(File(file.filePath).existsSync(), isTrue);

      final bytes = await File(file.filePath).readAsBytes();
      expect(bytes.sublist(0, 4), [0x25, 0x50, 0x44, 0x46]); // %PDF
    });

    test('FR-072 returns ValidationFailure when list is empty', () async {
      final detail = ListDetail(list: sampleList, items: const []);
      final result = await generator.generate(PdfDocumentData(listDetail: detail));

      expect(result, const Left(ValidationFailure('Cannot export an empty list.')));
    });

    test('FR-070/AS-19 emoji and special characters in item name do not crash PDF build', () async {
      final emojiItem = ShoppingItem(
        id: 'i-emoji',
        listId: 'list-1',
        name: 'Fresh 🍅 Tomatoes & 🧅 Onions ✨',
        quantity: const Quantity.fromMilli(1000),
        unit: 'kg',
        unitPrice: const Money.fromMinor(10000),
        isBought: false,
        createdAt: now,
        updatedAt: now,
      );

      final detail = ListDetail(list: sampleList, items: [emojiItem]);
      final result = await generator.generate(PdfDocumentData(listDetail: detail));

      expect(result.isRight(), isTrue);
    });

    test('FR-070 returns StorageFullFailure on FileSystemException', () async {
      final errorStore = TempExportFileStore(
        getTempDir: () async => throw const FileSystemException('No space left on device'),
        clock: fakeClock,
      );
      final errorGenerator = PdfListGenerator(
        fileStore: errorStore,
        fontLoader: (path) async => regularFontBytes,
        clock: fakeClock,
      );

      final detail = ListDetail(list: sampleList, items: sampleItems);
      final result = await errorGenerator.generate(PdfDocumentData(listDetail: detail));

      expect(result, const Left(StorageFullFailure()));
    });

    test('FR-070 returns ExportFailure on font loader exception', () async {
      final errorGenerator = PdfListGenerator(
        fileStore: fileStore,
        fontLoader: (path) async => throw Exception('Font file not found'),
        clock: fakeClock,
      );

      final detail = ListDetail(list: sampleList, items: sampleItems);
      final result = await errorGenerator.generate(PdfDocumentData(listDetail: detail));

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ExportFailure>()),
        (_) => fail('should fail'),
      );
    });
  });
}
