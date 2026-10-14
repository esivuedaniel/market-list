import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/exported_file.dart';
import 'package:market_list/features/export/domain/entities/pdf_document_data.dart';
import 'package:market_list/features/export/domain/services/list_pdf_generator.dart';
import 'package:market_list/features/export/domain/usecases/build_list_pdf.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

class MockListPdfGenerator extends Mock implements ListPdfGenerator {}

void main() {
  late MockShoppingItemRepository itemRepository;
  late MockListPdfGenerator pdfGenerator;
  late BuildListPdf useCase;

  setUp(() {
    itemRepository = MockShoppingItemRepository();
    pdfGenerator = MockListPdfGenerator();
    useCase = BuildListPdf(
      itemRepository: itemRepository,
      pdfGenerator: pdfGenerator,
    );
  });

  setUpAll(() {
    registerFallbackValue(PdfDocumentData(
      listDetail: ListDetail(
        list: ShoppingList(
          id: '1',
          name: 'Fallback',
          currency: CurrencyCode.usd,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        items: const [],
      ),
    ));
  });

  final now = DateTime.utc(2026, 10, 14);
  final list = ShoppingList(
    id: 'l1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );
  final item = ShoppingItem(
    id: '1',
    listId: 'l1',
    name: 'Tomatoes',
    quantity: const Quantity.fromMilli(2500),
    unit: 'kg',
    unitPrice: const Money.fromMinor(150000),
    isBought: false,
    createdAt: now,
    updatedAt: now,
  );
  const exportedFile = ExportedFile(
    filePath: '/path/to/Sunday-market-20261014.pdf',
    fileName: 'Sunday-market-20261014.pdf',
  );

  group('BuildListPdf', () {
    test('FR-072 returns ValidationFailure when list is empty', () async {
      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(ListDetail(list: list, items: const [])));

      final result = await useCase('l1');

      expect(result, const Left(ValidationFailure('Cannot export an empty list.')));
      verifyNever(() => pdfGenerator.generate(any()));
    });

    test('FR-070 builds PDF successfully when list has items', () async {
      final detail = ListDetail(list: list, items: [item]);
      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(detail));
      when(() => pdfGenerator.generate(PdfDocumentData(listDetail: detail)))
          .thenAnswer((_) async => const Right(exportedFile));

      final result = await useCase('l1');

      expect(result, const Right(exportedFile));
      expect(exportedFile.props, ['/path/to/Sunday-market-20261014.pdf', 'Sunday-market-20261014.pdf']);
      verify(() => pdfGenerator.generate(PdfDocumentData(listDetail: detail))).called(1);
    });

    test('FR-070 returns Failure when repository getListDetail fails', () async {
      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase('l1');

      expect(result, const Left(NotFoundFailure()));
      verifyNever(() => pdfGenerator.generate(any()));
    });

    test('FR-070 returns Failure when pdfGenerator fails', () async {
      final detail = ListDetail(list: list, items: [item]);
      when(() => itemRepository.getListDetail('l1'))
          .thenAnswer((_) async => Right(detail));
      when(() => pdfGenerator.generate(any()))
          .thenAnswer((_) async => const Left(ExportFailure('PDF failed')));

      final result = await useCase('l1');

      expect(result, const Left(ExportFailure('PDF failed')));
    });
  });
}
