import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/duplicate_list.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late DuplicateList useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = DuplicateList(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final duplicatedList = ShoppingList(
    id: 'list-2',
    name: 'Sunday market (copy)',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );

  group('DuplicateList', () {
    test('FR-004 duplicates list successfully when below 100 limit', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(5));
      when(() => repository.duplicateList('list-1'))
          .thenAnswer((_) async => Right(duplicatedList));

      final result = await useCase('list-1');

      expect(result, Right(duplicatedList));
      verify(() => repository.duplicateList('list-1')).called(1);
    });

    test('FR-005 returns LimitFailure when list count is at 100 limit', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(AppLimits.maxLists));

      final result = await useCase('list-1');

      expect(result, const Left(LimitFailure(LimitKind.lists)));
      verifyNever(() => repository.duplicateList(any()));
    });

    test('FR-004 returns Failure when repository listCount fails', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase('list-1');

      expect(result, const Left(DatabaseFailure('DB error')));
    });

    test('FR-004 returns Failure when repository duplicateList fails', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(5));
      when(() => repository.duplicateList('list-1'))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase('list-1');

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
