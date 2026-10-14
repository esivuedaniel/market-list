import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/exported_file.dart';
import 'package:market_list/features/export/domain/entities/pdf_document_data.dart';

abstract class ListPdfGenerator {
  Future<Either<Failure, ExportedFile>> generate(PdfDocumentData data);
}
