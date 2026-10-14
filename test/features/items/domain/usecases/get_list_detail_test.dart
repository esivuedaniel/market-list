import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/get_list_detail.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late GetListDetail useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = GetListDetail(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final list = ShoppingList(
    id: 'l1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );
  final detail = ListDetail(list: list, items: const []);

  group('GetListDetail', () {
    test('FR-010 returns ListDetail on success', () async {
      when(() => repository.getListDetail('l1'))
          .thenAnswer((_) async => Right(detail));

      final result = await useCase('l1');

      expect(result, Right(detail));
      verify(() => repository.getListDetail('l1')).called(1);
    });

    test('FR-010 returns NotFoundFailure when list is not found', () async {
      when(() => repository.getListDetail('missing'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase('missing');

      expect(result, const Left(NotFoundFailure()));
    });
  });
}
