import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/formatting/date_formatter.dart';
import 'package:market_list/core/formatting/money_formatter.dart';
import 'package:market_list/core/formatting/quantity_formatter.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/features/export/data/services/temp_export_file_store.dart';
import 'package:market_list/features/export/domain/entities/exported_file.dart';
import 'package:market_list/features/export/domain/entities/pdf_document_data.dart';
import 'package:market_list/features/export/domain/services/list_pdf_generator.dart';

typedef FontBytesLoader = Future<Uint8List> Function(String path);

class _PdfJobData {
  const _PdfJobData({
    required this.regularFontBytes,
    required this.boldFontBytes,
    required this.listName,
    required this.dateStr,
    required this.itemCountStr,
    required this.currencySymbol,
    required this.items,
    required this.totalAmountStr,
  });

  final Uint8List regularFontBytes;
  final Uint8List boldFontBytes;
  final String listName;
  final String dateStr;
  final String itemCountStr;
  final String currencySymbol;
  final List<_PdfJobItem> items;
  final String totalAmountStr;
}

class _PdfJobItem {
  const _PdfJobItem({
    required this.index,
    required this.name,
    required this.quantityWithUnit,
    required this.unitPriceStr,
    required this.lineTotalStr,
    required this.isBought,
  });

  final int index;
  final String name;
  final String quantityWithUnit;
  final String unitPriceStr;
  final String lineTotalStr;
  final bool isBought;
}

class PdfListGenerator implements ListPdfGenerator {
  PdfListGenerator({
    TempExportFileStore? fileStore,
    FontBytesLoader? fontLoader,
    Clock clock = const Clock(),
  })  : _fileStore = fileStore ?? TempExportFileStore(),
        _fontLoader = fontLoader ?? _defaultFontLoader,
        _clock = clock;

  final TempExportFileStore _fileStore;
  final FontBytesLoader _fontLoader;
  final Clock _clock;

  static Future<Uint8List> _defaultFontLoader(String path) async {
    final byteData = await rootBundle.load(path);
    return byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
  }

  @override
  Future<Either<Failure, ExportedFile>> generate(PdfDocumentData data) async {
    final detail = data.listDetail;
    if (detail.items.isEmpty) {
      return const Left(ValidationFailure('Cannot export an empty list.'));
    }

    try {
      final regularBytes = await _fontLoader('assets/fonts/NotoSans-Regular.ttf');
      final boldBytes = await _fontLoader('assets/fonts/NotoSans-Bold.ttf');

      final items = <_PdfJobItem>[];
      for (var i = 0; i < detail.items.length; i++) {
        final item = detail.items[i];
        final qtyStr = QuantityFormatter.format(item.quantity);
        final qtyWithUnit = (item.unit != null && item.unit!.isNotEmpty)
            ? '$qtyStr ${item.unit}'
            : qtyStr;
        items.add(_PdfJobItem(
          index: i + 1,
          name: item.name,
          quantityWithUnit: qtyWithUnit,
          unitPriceStr: MoneyFormatter.formatAmount(item.unitPrice),
          lineTotalStr: MoneyFormatter.formatAmount(item.lineTotal),
          isBought: item.isBought,
        ));
      }

      final now = _clock.now();
      final job = _PdfJobData(
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
        listName: detail.list.name,
        dateStr: DateFormatter.format(now),
        itemCountStr: '${detail.items.length}',
        currencySymbol: detail.list.currency.symbol,
        items: items,
        totalAmountStr: MoneyFormatter.format(detail.total, detail.list.currency),
      );

      final pdfBytes = await Isolate.run(() => _buildPdfBytes(job));

      final fileName = TempExportFileStore.generateExportFileName(detail.list.name, now);
      final file = await _fileStore.getExportFile(fileName);
      await file.writeAsBytes(pdfBytes, flush: true);

      return Right(ExportedFile(filePath: file.path, fileName: fileName));
    } on FileSystemException {
      return const Left(StorageFullFailure());
    } on Exception catch (e) {
      return Left(ExportFailure(e.toString()));
    }
  }

  static Future<Uint8List> _buildPdfBytes(_PdfJobData job) async {
    final regularFont = pw.Font.ttf(job.regularFontBytes.buffer.asByteData());
    final boldFont = pw.Font.ttf(job.boldFontBytes.buffer.asByteData());

    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                job.listName,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  color: PdfColor.fromHex('#1A1A1A'),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Container(height: 2, color: PdfColor.fromHex('#F57C00')),
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4, bottom: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ${job.dateStr}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#5E5750'),
                      ),
                    ),
                    pw.Text(
                      'Items: ${job.itemCountStr}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#5E5750'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Made with Market List',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#5E5750'),
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#5E5750'),
                ),
              ),
            ],
          );
        },
        build: (context) {
          return [
            _buildItemsTable(job, boldFont),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemsTable(_PdfJobData job, pw.Font boldFont) {
    const headerBg = PdfColor.fromInt(0xFFFFE0B2);
    const headerTextColor = PdfColor.fromInt(0xFF3E2000);
    const zebraBg = PdfColor.fromInt(0xFFFFF8F0);
    const borderColor = PdfColor.fromInt(0xFFE0D6CB);
    const padding = pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5);

    final rows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: headerBg),
        children: [
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.center,
            child: pw.Text('Done', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('No.', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.centerLeft,
            child: pw.Text('Item', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Qty', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Unit price (${job.currencySymbol})', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
          pw.Container(
            padding: padding,
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Line total (${job.currencySymbol})', style: pw.TextStyle(font: boldFont, fontSize: 10, color: headerTextColor)),
          ),
        ],
      ),
    ];

    final count = job.items.length;
    for (var i = 0; i < count; i++) {
      final item = job.items[i];
      final isLast = i == count - 1;
      final isZebra = i.isOdd;
      final rowBg = isZebra ? zebraBg : const PdfColor(1, 1, 1);

      if (!isLast) {
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowBg,
              border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1)),
            ),
            children: [
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.center,
                child: _buildCheckSquare(item.isBought),
              ),
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('${item.index}', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(item.name, maxLines: 3, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(item.quantityWithUnit, maxLines: 2, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(item.unitPriceStr, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: padding,
                alignment: pw.Alignment.centerRight,
                child: pw.Text(item.lineTotalStr, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          ),
        );
      } else {
        // Last row keeps the last item and the total row together in one atomic TableRow
        rows.add(
          pw.TableRow(
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.center,
                    child: _buildCheckSquare(item.isBought),
                  ),
                  pw.Container(color: headerBg, padding: padding, child: pw.Text(' ', style: const pw.TextStyle(fontSize: 12))),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('${item.index}', style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(color: headerBg, padding: padding, child: pw.Text(' ', style: const pw.TextStyle(fontSize: 12))),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(item.name, maxLines: 3, style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(color: headerBg, padding: padding, child: pw.Text(' ', style: const pw.TextStyle(fontSize: 12))),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(item.quantityWithUnit, maxLines: 2, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(color: headerBg, padding: padding, child: pw.Text(' ', style: const pw.TextStyle(fontSize: 12))),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(item.unitPriceStr, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(
                    color: headerBg,
                    padding: padding,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Total', style: pw.TextStyle(font: boldFont, fontSize: 12, color: headerTextColor)),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(color: rowBg, border: const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1))),
                    padding: padding,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(item.lineTotalStr, textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                  ),
                  pw.Container(
                    color: headerBg,
                    padding: padding,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(job.totalAmountStr, style: pw.TextStyle(font: boldFont, fontSize: 12, color: headerTextColor)),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(28),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(2),
        4: const pw.IntrinsicColumnWidth(),
        5: const pw.IntrinsicColumnWidth(),
      },
      children: rows,
    );
  }

  static pw.Widget _buildCheckSquare(bool isBought) {
    return pw.CustomPaint(
      size: const PdfPoint(10, 10),
      painter: (canvas, size) {
        canvas.setColor(PdfColor.fromHex('#5E5750'));
        canvas.setLineWidth(1);
        canvas.drawRect(0, 0, 10, 10);
        canvas.strokePath();

        if (isBought) {
          canvas.setColor(PdfColor.fromHex('#F57C00'));
          canvas.setLineWidth(1.5);
          canvas.moveTo(2, 5);
          canvas.lineTo(4.5, 2.5);
          canvas.lineTo(8, 7.5);
          canvas.strokePath();
        }
      },
    );
  }
}
