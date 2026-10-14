import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/watch_lists.dart';

class MockShoppingListRepository extends Mock implements ShoppingListRepository {}

void main() {
  late MockShoppingListRepository repository;
  late WatchLists useCase;

  setUp(() {
    repository = MockShoppingListRepository();
    useCase = WatchLists(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final list = ShoppingList(
    id: 'list-1',
    name: 'Sunday market',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );
  final summaries = [
    ListSummary(
      list: list,
      itemCount: 3,
      total: const Money(4935000),
    ),
  ];

  group('WatchLists', () {
    test('FR-001 emits Right with list summaries from repository', () async {
      when(() => repository.watchLists())
          .thenAnswer((_) => Stream.value(Right(summaries)));

      final stream = useCase(const NoParams());

      expect(
        stream,
        emits(Right<Failure, List<ListSummary>>(summaries)),
      );
      verify(() => repository.watchLists()).called(1);
    });

    test('FR-001 emits Left with Failure when repository fails', () async {
      when(() => repository.watchLists())
          .thenAnswer((_) => Stream.value(const Left(DatabaseFailure('DB error'))));

      final stream = useCase(const NoParams());

      expect(
        stream,
        emits(const Left<Failure, List<ListSummary>>(DatabaseFailure('DB error'))),
      );
    });
  });
}
