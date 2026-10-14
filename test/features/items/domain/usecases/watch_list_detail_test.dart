import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';
import 'package:market_list/features/items/domain/usecases/watch_list_detail.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockShoppingItemRepository extends Mock implements ShoppingItemRepository {}

void main() {
  late MockShoppingItemRepository repository;
  late WatchListDetail useCase;

  setUp(() {
    repository = MockShoppingItemRepository();
    useCase = WatchListDetail(repository);
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

  group('WatchListDetail', () {
    test('FR-010 emits ListDetail from repository stream', () async {
      when(() => repository.watchListDetail('l1'))
          .thenAnswer((_) => Stream.value(Right(detail)));

      final stream = useCase('l1');

      expect(stream, emits(Right<Failure, ListDetail>(detail)));
      verify(() => repository.watchListDetail('l1')).called(1);
    });

    test('FR-010 emits Failure when repository stream emits Left', () async {
      when(() => repository.watchListDetail('l1'))
          .thenAnswer((_) => Stream.value(const Left(DatabaseFailure('DB error'))));

      final stream = useCase('l1');

      expect(
        stream,
        emits(const Left<Failure, ListDetail>(DatabaseFailure('DB error'))),
      );
    });
  });
}
