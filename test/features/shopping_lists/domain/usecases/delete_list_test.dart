import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late DeleteList useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = DeleteList(repository);
  });

  group('DeleteList', () {
    test('FR-003 deletes list successfully (triggers cascade in repository)', () async {
      when(() => repository.deleteList('list-1'))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase('list-1');

      expect(result, const Right(unit));
      verify(() => repository.deleteList('list-1')).called(1);
    });

    test('FR-003 returns failure when repository fails to delete list', () async {
      when(() => repository.deleteList('list-1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase('list-1');

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
