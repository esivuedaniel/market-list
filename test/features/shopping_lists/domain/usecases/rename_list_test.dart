import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late RenameList useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = RenameList(repository);
  });

  group('RenameList', () {
    test('FR-002 renames list successfully with normalized name', () async {
      when(() => repository.renameList(
            id: 'list-1',
            name: 'Saturday market',
          )).thenAnswer((_) async => const Right(unit));

      final result = await useCase(const RenameListParams(
        listId: 'list-1',
        name: '  Saturday   market  ',
      ));

      expect(result, const Right(unit));
      verify(() => repository.renameList(
            id: 'list-1',
            name: 'Saturday market',
          )).called(1);
    });

    test('FR-002 returns ValidationFailure when name is empty', () async {
      final result = await useCase(const RenameListParams(
        listId: 'list-1',
        name: '    ',
      ));

      expect(result, const Left(ValidationFailure('Enter a list name.')));
      verifyNever(() => repository.renameList(
            id: any(named: 'id'),
            name: any(named: 'name'),
          ));
    });

    test('FR-002 returns ValidationFailure when name exceeds 60 characters', () async {
      final result = await useCase(RenameListParams(
        listId: 'list-1',
        name: 'B' * 61,
      ));

      expect(
        result,
        const Left(ValidationFailure('List name must be 60 characters or fewer.')),
      );
      verifyNever(() => repository.renameList(
            id: any(named: 'id'),
            name: any(named: 'name'),
          ));
    });

    test('FR-002 returns NotFoundFailure when repository cannot find list', () async {
      when(() => repository.renameList(
            id: 'non-existent',
            name: 'Valid Name',
          )).thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(const RenameListParams(
        listId: 'non-existent',
        name: 'Valid Name',
      ));

      expect(result, const Left(NotFoundFailure()));
      expect(const RenameListParams(listId: 'non-existent', name: 'Valid Name').props, ['non-existent', 'Valid Name']);
    });
  });
}
