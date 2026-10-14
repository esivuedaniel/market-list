import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/export/domain/entities/exported_file.dart';
import 'package:market_list/features/export/domain/entities/pdf_document_data.dart';
import 'package:market_list/features/export/domain/services/list_pdf_generator.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class BuildListPdf implements UseCase<ExportedFile, String> {
  const BuildListPdf({
    required ShoppingItemRepository itemRepository,
    required ListPdfGenerator pdfGenerator,
  })  : _itemRepository = itemRepository,
        _pdfGenerator = pdfGenerator;

  final ShoppingItemRepository _itemRepository;
  final ListPdfGenerator _pdfGenerator;

  @override
  Future<Either<Failure, ExportedFile>> call(String listId) async {
    final detailResult = await _itemRepository.getListDetail(listId);
    return detailResult.fold(
      Left.new,
      (detail) {
        if (detail.items.isEmpty) {
          return const Left(ValidationFailure('Cannot export an empty list.'));
        }
        return _pdfGenerator.generate(PdfDocumentData(listDetail: detail));
      },
    );
  }
}
