import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/has_duplicate_item_name.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late HasDuplicateItemName useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = HasDuplicateItemName(repository);
  });

  group('HasDuplicateItemName', () {
    test('FR-020 normalizes name before checking duplicate', () async {
      when(() => repository.hasDuplicateName(
            listId: 'list-1',
            name: 'Tomatoes',
            excludeId: null,
          )).thenAnswer((_) async => const Right(true));

      final result = await useCase(const DuplicateCheckParams(
        listId: 'list-1',
        name: '  Tomatoes  ',
      ));

      expect(result, const Right(true));
      verify(() => repository.hasDuplicateName(
            listId: 'list-1',
            name: 'Tomatoes',
            excludeId: null,
          )).called(1);
    });

    test('FR-020 passes excludeId when editing item', () async {
      when(() => repository.hasDuplicateName(
            listId: 'list-1',
            name: 'Tomatoes',
            excludeId: 'item-1',
          )).thenAnswer((_) async => const Right(false));

      final result = await useCase(const DuplicateCheckParams(
        listId: 'list-1',
        name: 'Tomatoes',
        excludeItemId: 'item-1',
      ));

      expect(result, const Right(false));
      verify(() => repository.hasDuplicateName(
            listId: 'list-1',
            name: 'Tomatoes',
            excludeId: 'item-1',
          )).called(1);
    });

    test('FR-020 returns false when name is empty after normalization', () async {
      final result = await useCase(const DuplicateCheckParams(
        listId: 'list-1',
        name: '    ',
      ));

      expect(result, const Right(false));
      verifyNever(() => repository.hasDuplicateName(
            listId: any(named: 'listId'),
            name: any(named: 'name'),
            excludeId: any(named: 'excludeId'),
          ));
    });

    test('FR-020 returns Failure when repository check fails', () async {
      when(() => repository.hasDuplicateName(
            listId: 'list-1',
            name: 'Tomatoes',
            excludeId: null,
          )).thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(const DuplicateCheckParams(
        listId: 'list-1',
        name: 'Tomatoes',
      ));

      expect(result, const Left(DatabaseFailure('DB error')));
      expect(const DuplicateCheckParams(listId: 'list-1', name: 'Tomatoes').props, ['list-1', 'Tomatoes', null]);
    });
  });
}
