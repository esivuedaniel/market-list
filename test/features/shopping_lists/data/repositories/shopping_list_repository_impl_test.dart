import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/shopping_lists/data/datasources/shopping_list_local_data_source.dart';
import 'package:market_list/features/shopping_lists/data/mappers/shopping_list_mapper.dart';
import 'package:market_list/features/shopping_lists/data/repositories/shopping_list_repository_impl.dart';

class MockShoppingListLocalDataSource extends Mock
    implements ShoppingListLocalDataSource {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockClock extends Mock implements Clock {}

void main() {
  late MockShoppingListLocalDataSource mockDataSource;
  late ShoppingListMapper mapper;
  late MockIdGenerator mockIdGenerator;
  late MockClock mockClock;
  late ShoppingListRepositoryImpl repository;

  final testNow = DateTime.utc(2026, 10, 14, 12, 0);

  setUpAll(() {
    registerFallbackValue(
      ShoppingListsTableCompanion.insert(
        id: 'fallback-id',
        name: 'Fallback',
        currencyCode: 'USD',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockShoppingListLocalDataSource();
    mapper = const ShoppingListMapper();
    mockIdGenerator = MockIdGenerator();
    mockClock = MockClock();

    when(() => mockClock.now()).thenReturn(testNow);
    when(() => mockIdGenerator.generate()).thenReturn('generated-uuid');

    repository = ShoppingListRepositoryImpl(
      dataSource: mockDataSource,
      mapper: mapper,
      idGenerator: mockIdGenerator,
      clock: mockClock,
    );
  });

  group('ShoppingListRepositoryImpl', () {
    test('FR-080 createList inserts and returns ShoppingList', () async {
      when(() => mockDataSource.insertList(any())).thenAnswer((_) async {});

      final result = await repository.createList(
        name: 'Weekly Shop',
        currency: CurrencyCode.usd,
      );

      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.id, 'generated-uuid');
          expect(r.name, 'Weekly Shop');
          expect(r.currency, CurrencyCode.usd);
          expect(r.createdAt, testNow);
        },
      );
    });

    test('FR-080 createList returns Left when data source throws', () async {
      when(() => mockDataSource.insertList(any()))
          .thenThrow(SqliteException(13, 'disk full'));

      final result = await repository.createList(
        name: 'Weekly Shop',
        currency: CurrencyCode.usd,
      );

      expect(result, const Left(StorageFullFailure()));
    });

    test('FR-080 renameList returns Right(unit) on success', () async {
      when(() => mockDataSource.renameList('list-1', 'New Name', testNow.millisecondsSinceEpoch))
          .thenAnswer((_) async => 1);

      final result = await repository.renameList(id: 'list-1', name: 'New Name');
      expect(result, const Right(unit));
    });

    test('FR-080 renameList returns NotFoundFailure when row count is 0', () async {
      when(() => mockDataSource.renameList('list-1', 'New Name', testNow.millisecondsSinceEpoch))
          .thenAnswer((_) async => 0);

      final result = await repository.renameList(id: 'list-1', name: 'New Name');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 renameList returns Left when data source throws', () async {
      when(() => mockDataSource.renameList('list-1', 'New Name', any()))
          .thenThrow(SqliteException(1, 'db error'));

      final result = await repository.renameList(id: 'list-1', name: 'New Name');
      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('FR-080 setCurrency returns Right(unit) on success', () async {
      when(() => mockDataSource.setCurrency('list-1', 'EUR', testNow.millisecondsSinceEpoch))
          .thenAnswer((_) async => 1);

      final result = await repository.setCurrency(id: 'list-1', currency: CurrencyCode.eur);
      expect(result, const Right(unit));
    });

    test('FR-080 setCurrency returns NotFoundFailure when row count is 0', () async {
      when(() => mockDataSource.setCurrency('list-1', 'EUR', testNow.millisecondsSinceEpoch))
          .thenAnswer((_) async => 0);

      final result = await repository.setCurrency(id: 'list-1', currency: CurrencyCode.eur);
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 setCurrency returns Left when data source throws', () async {
      when(() => mockDataSource.setCurrency('list-1', 'EUR', any()))
          .thenThrow(SqliteException(1, 'db error'));

      final result = await repository.setCurrency(id: 'list-1', currency: CurrencyCode.eur);
      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('FR-080 deleteList returns Right(unit) on success', () async {
      when(() => mockDataSource.getList('list-1')).thenAnswer(
        (_) async => const ShoppingListRow(
          id: 'list-1',
          name: 'Shop',
          currencyCode: 'USD',
          createdAt: 1000,
          updatedAt: 1000,
        ),
      );
      when(() => mockDataSource.deleteList('list-1')).thenAnswer((_) async => 1);

      final result = await repository.deleteList('list-1');
      expect(result, const Right(unit));
    });

    test('FR-080 deleteList returns NotFoundFailure when list does not exist', () async {
      when(() => mockDataSource.getList('list-1')).thenAnswer((_) async => null);

      final result = await repository.deleteList('list-1');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 deleteList returns Left when data source throws', () async {
      when(() => mockDataSource.getList('list-1')).thenThrow(SqliteException(1, 'db error'));

      final result = await repository.deleteList('list-1');
      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('FR-080 duplicateList returns LimitFailure when list count >= 100', () async {
      when(() => mockDataSource.listCount()).thenAnswer((_) async => AppLimits.maxLists);

      final result = await repository.duplicateList('list-1');
      expect(result, const Left(LimitFailure(LimitKind.lists)));
    });

    test('FR-080 duplicateList returns NotFoundFailure when source does not exist', () async {
      when(() => mockDataSource.listCount()).thenAnswer((_) async => 5);
      when(() => mockDataSource.getList('list-1')).thenAnswer((_) async => null);

      final result = await repository.duplicateList('list-1');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 duplicateList duplicates and returns ShoppingList', () async {
      when(() => mockDataSource.listCount()).thenAnswer((_) async => 5);
      when(() => mockDataSource.getList('list-1')).thenAnswer(
        (_) async => const ShoppingListRow(
          id: 'list-1',
          name: 'Shop',
          currencyCode: 'USD',
          createdAt: 1000,
          updatedAt: 1000,
        ),
      );
      when(
        () => mockDataSource.duplicateList(
          sourceId: 'list-1',
          newId: any(named: 'newId'),
          newName: 'Shop',
          nowEpochMs: any(named: 'nowEpochMs'),
          newItemIds: any(named: 'newItemIds'),
        ),
      ).thenAnswer(
        (_) async => ShoppingListRow(
          id: 'generated-uuid',
          name: 'Shop',
          currencyCode: 'USD',
          createdAt: testNow.millisecondsSinceEpoch,
          updatedAt: testNow.millisecondsSinceEpoch,
        ),
      );

      final result = await repository.duplicateList('list-1');
      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) => expect(r.id, 'generated-uuid'),
      );
    });

    test('FR-080 duplicateList returns Left when data source throws', () async {
      when(() => mockDataSource.listCount()).thenThrow(SqliteException(1, 'db error'));

      final result = await repository.duplicateList('list-1');
      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('FR-080 listCount returns Right(count)', () async {
      when(() => mockDataSource.listCount()).thenAnswer((_) async => 42);

      final result = await repository.listCount();
      expect(result, const Right(42));
    });

    test('FR-080 listCount returns Left when data source throws', () async {
      when(() => mockDataSource.listCount()).thenThrow(SqliteException(1, 'db error'));

      final result = await repository.listCount();
      expect(result, const Left(DatabaseFailure('db error')));
    });

    test('FR-080 watchLists emits mapped summaries and handles errors', () async {
      const summaryRow = ListSummaryRow(
        list: ShoppingListRow(
          id: 'list-1',
          name: 'Shop',
          currencyCode: 'USD',
          createdAt: 1000,
          updatedAt: 1000,
        ),
        itemCount: 2,
        totalMinor: 500,
      );

      when(() => mockDataSource.watchSummaries())
          .thenAnswer((_) => Stream.value([summaryRow]));

      final items = await repository.watchLists().first;
      expect(items.isRight(), isTrue);

      // Stream error case
      when(() => mockDataSource.watchSummaries())
          .thenAnswer((_) => Stream.error(SqliteException(13, 'disk full')));

      final errItems = await repository.watchLists().first;
      expect(errItems, const Left(StorageFullFailure()));
    });
  });
}
