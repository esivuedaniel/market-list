import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/create_list.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late CreateList useCase;

  setUpAll(() {
    registerFallbackValue(CurrencyCode.usd);
  });

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = CreateList(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final expectedList = ShoppingList(
    id: 'list-1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );

  group('CreateList', () {
    test('FR-001 creates list successfully after normalization', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(0));
      when(() => repository.createList(
            name: 'Sunday market',
            currency: CurrencyCode.ngn,
          )).thenAnswer((_) async => Right(expectedList));

      final result = await useCase(const CreateListParams(
        name: '  Sunday   market  ',
        currency: CurrencyCode.ngn,
      ));

      expect(result, Right(expectedList));
      verify(() => repository.createList(
            name: 'Sunday market',
            currency: CurrencyCode.ngn,
          )).called(1);
    });

    test('FR-001 returns ValidationFailure when name is empty after normalization', () async {
      final result = await useCase(const CreateListParams(
        name: '   \n  \t  ',
        currency: CurrencyCode.ngn,
      ));

      expect(result, const Left(ValidationFailure('Enter a list name.')));
      verifyNever(() => repository.listCount());
      verifyNever(() => repository.createList(
            name: any(named: 'name'),
            currency: any(named: 'currency'),
          ));
    });

    test('FR-001 returns ValidationFailure when name exceeds 60 characters', () async {
      final longName = 'A' * 61;
      final result = await useCase(CreateListParams(
        name: longName,
        currency: CurrencyCode.ngn,
      ));

      expect(
        result,
        const Left(ValidationFailure('List name must be 60 characters or fewer.')),
      );
      verifyNever(() => repository.listCount());
    });

    test('FR-005 returns LimitFailure when list count is at 100 limit', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(AppLimits.maxLists));

      final result = await useCase(const CreateListParams(
        name: 'New list',
        currency: CurrencyCode.ngn,
      ));

      expect(result, const Left(LimitFailure(LimitKind.lists)));
      verify(() => repository.listCount()).called(1);
      verifyNever(() => repository.createList(
            name: any(named: 'name'),
            currency: any(named: 'currency'),
          ));
    });

    test('FR-001 returns Failure when repository listCount fails', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(const CreateListParams(
        name: 'New list',
        currency: CurrencyCode.ngn,
      ));

      expect(result, const Left(DatabaseFailure('DB error')));
    });

    test('FR-001 returns Failure when repository createList fails', () async {
      when(() => repository.listCount())
          .thenAnswer((_) async => const Right(0));
      when(() => repository.createList(
            name: 'New list',
            currency: CurrencyCode.ngn,
          )).thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(const CreateListParams(
        name: 'New list',
        currency: CurrencyCode.ngn,
      ));

      expect(result, const Left(DatabaseFailure('DB error')));
      expect(const CreateListParams(name: 'New list', currency: CurrencyCode.ngn).props, ['New list', CurrencyCode.ngn]);
    });
  });
}
