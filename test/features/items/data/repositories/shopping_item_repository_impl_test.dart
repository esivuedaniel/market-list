import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/items_dao.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/items/data/datasources/shopping_item_local_data_source.dart';
import 'package:market_list/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:market_list/features/items/data/repositories/shopping_item_repository_impl.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

class MockShoppingItemLocalDataSource extends Mock
    implements ShoppingItemLocalDataSource {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockClock extends Mock implements Clock {}

void main() {
  late MockShoppingItemLocalDataSource mockDataSource;
  late ShoppingItemMapper mapper;
  late MockIdGenerator mockIdGenerator;
  late MockClock mockClock;
  late ShoppingItemRepositoryImpl repository;

  final testNow = DateTime.utc(2026, 10, 14, 12, 0);

  const testItemRow = ShoppingItemRow(
    id: 'item-1',
    listId: 'list-1',
    name: 'Apples',
    quantityMilli: 1000,
    unit: 'kg',
    unitPriceMinor: 200,
    isBought: false,
    createdAt: 1000,
    updatedAt: 1000,
  );

  const testListRow = ShoppingListRow(
    id: 'list-1',
    name: 'Groceries',
    currencyCode: 'USD',
    createdAt: 1000,
    updatedAt: 1000,
  );

  setUpAll(() {
    registerFallbackValue(
      ShoppingItemsTableCompanion.insert(
        id: 'fb-id',
        listId: 'fb-list',
        name: 'fb-name',
        quantityMilli: 1000,
        unitPriceMinor: 100,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    registerFallbackValue(
      const ShoppingItemRow(
        id: 'fb-id',
        listId: 'fb-list',
        name: 'fb-name',
        quantityMilli: 1000,
        unitPriceMinor: 100,
        isBought: false,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockShoppingItemLocalDataSource();
    mapper = const ShoppingItemMapper();
    mockIdGenerator = MockIdGenerator();
    mockClock = MockClock();

    when(() => mockClock.now()).thenReturn(testNow);
    when(() => mockIdGenerator.generate()).thenReturn('item-generated-id');

    repository = ShoppingItemRepositoryImpl(
      dataSource: mockDataSource,
      mapper: mapper,
      idGenerator: mockIdGenerator,
      clock: mockClock,
    );
  });

  group('ShoppingItemRepositoryImpl', () {
    test('FR-080 watchListDetail emits ListDetail and handles NotFound/error', () async {
      // 1. Success
      when(() => mockDataSource.watchListWithItems('list-1')).thenAnswer(
        (_) => Stream.value(const ListDetailRow(list: testListRow, items: [testItemRow])),
      );
      final successRes = await repository.watchListDetail('list-1').first;
      expect(successRes.isRight(), isTrue);

      // 2. Not found
      when(() => mockDataSource.watchListWithItems('list-missing')).thenAnswer(
        (_) => Stream.value(null),
      );
      final notFoundRes = await repository.watchListDetail('list-missing').first;
      expect(notFoundRes, const Left(NotFoundFailure()));

      // 3. Error
      when(() => mockDataSource.watchListWithItems('list-err')).thenAnswer(
        (_) => Stream.error(SqliteException(13, 'disk full')),
      );
      final errRes = await repository.watchListDetail('list-err').first;
      expect(errRes, const Left(StorageFullFailure()));
    });

    test('FR-080 getListDetail returns Right(ListDetail) on success', () async {
      when(() => mockDataSource.getListDetail('list-1')).thenAnswer(
        (_) async => const ListDetailRow(list: testListRow, items: [testItemRow]),
      );

      final result = await repository.getListDetail('list-1');
      expect(result.isRight(), isTrue);
    });

    test('FR-080 getListDetail returns NotFoundFailure when null', () async {
      when(() => mockDataSource.getListDetail('list-1')).thenAnswer((_) async => null);

      final result = await repository.getListDetail('list-1');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 getListDetail returns Left when data source throws', () async {
      when(() => mockDataSource.getListDetail('list-1')).thenThrow(SqliteException(1, 'db err'));

      final result = await repository.getListDetail('list-1');
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 getItem returns Right(ShoppingItem) on success', () async {
      when(() => mockDataSource.getItem('item-1')).thenAnswer((_) async => testItemRow);

      final result = await repository.getItem('item-1');
      expect(result.isRight(), isTrue);
      result.match((l) => fail('Expected Right'), (r) => expect(r.name, 'Apples'));
    });

    test('FR-080 getItem returns NotFoundFailure when item is null', () async {
      when(() => mockDataSource.getItem('item-1')).thenAnswer((_) async => null);

      final result = await repository.getItem('item-1');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 getItem returns Left when data source throws', () async {
      when(() => mockDataSource.getItem('item-1')).thenThrow(SqliteException(1, 'db err'));

      final result = await repository.getItem('item-1');
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 addItem inserts companion and returns ShoppingItem', () async {
      const draft = ItemDraft(
        name: 'Milk',
        quantity: Quantity(2000),
        unit: 'l',
        unitPrice: Money(180),
      );

      when(() => mockDataSource.insertItem(any(), any())).thenAnswer(
        (_) async => ShoppingItemRow(
          id: 'item-generated-id',
          listId: 'list-1',
          name: 'Milk',
          quantityMilli: 2000,
          unit: 'l',
          unitPriceMinor: 180,
          isBought: false,
          createdAt: testNow.millisecondsSinceEpoch,
          updatedAt: testNow.millisecondsSinceEpoch,
        ),
      );

      final result = await repository.addItem(listId: 'list-1', draft: draft);
      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.id, 'item-generated-id');
          expect(r.name, 'Milk');
        },
      );
    });

    test('FR-080 addItem returns Left when data source throws', () async {
      const draft = ItemDraft(
        name: 'Milk',
        quantity: Quantity(2000),
        unit: 'l',
        unitPrice: Money(180),
      );

      when(() => mockDataSource.insertItem(any(), any()))
          .thenThrow(SqliteException(13, 'disk full'));

      final result = await repository.addItem(listId: 'list-1', draft: draft);
      expect(result, const Left(StorageFullFailure()));
    });

    test('FR-080 updateItem updates and returns ShoppingItem', () async {
      const draft = ItemDraft(
        name: 'Apples Gala',
        quantity: Quantity(1500),
        unit: 'kg',
        unitPrice: Money(220),
      );

      when(() => mockDataSource.updateItem(any(), any())).thenAnswer(
        (_) async => ShoppingItemRow(
          id: 'item-1',
          listId: 'list-1',
          name: 'Apples Gala',
          quantityMilli: 1500,
          unit: 'kg',
          unitPriceMinor: 220,
          isBought: false,
          createdAt: 1000,
          updatedAt: testNow.millisecondsSinceEpoch,
        ),
      );

      final result = await repository.updateItem(id: 'item-1', draft: draft);
      expect(result.isRight(), isTrue);
      result.match((l) => fail('Expected Right'), (r) => expect(r.name, 'Apples Gala'));
    });

    test('FR-080 updateItem returns NotFoundFailure when row is null', () async {
      const draft = ItemDraft(
        name: 'Apples Gala',
        quantity: Quantity(1500),
        unit: 'kg',
        unitPrice: Money(220),
      );

      when(() => mockDataSource.updateItem(any(), any())).thenAnswer((_) async => null);

      final result = await repository.updateItem(id: 'item-1', draft: draft);
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 updateItem returns Left when data source throws', () async {
      const draft = ItemDraft(
        name: 'Apples Gala',
        quantity: Quantity(1500),
        unit: 'kg',
        unitPrice: Money(220),
      );

      when(() => mockDataSource.updateItem(any(), any())).thenThrow(SqliteException(1, 'db err'));

      final result = await repository.updateItem(id: 'item-1', draft: draft);
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 deleteItem deletes and returns ShoppingItem', () async {
      when(() => mockDataSource.deleteItem('item-1', any())).thenAnswer((_) async => testItemRow);

      final result = await repository.deleteItem('item-1');
      expect(result.isRight(), isTrue);
      result.match((l) => fail('Expected Right'), (r) => expect(r.id, 'item-1'));
    });

    test('FR-080 deleteItem returns NotFoundFailure when row is null', () async {
      when(() => mockDataSource.deleteItem('item-1', any())).thenAnswer((_) async => null);

      final result = await repository.deleteItem('item-1');
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 deleteItem returns Left when data source throws', () async {
      when(() => mockDataSource.deleteItem('item-1', any())).thenThrow(SqliteException(1, 'db err'));

      final result = await repository.deleteItem('item-1');
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 restoreItem restores ShoppingItem', () async {
      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Apples',
        quantity: const Quantity(1000),
        unit: 'kg',
        unitPrice: const Money(200),
        isBought: false,
        createdAt: testNow,
        updatedAt: testNow,
      );

      when(() => mockDataSource.restoreItem(any(), any())).thenAnswer((_) async {});

      final result = await repository.restoreItem(item);
      expect(result, const Right(unit));
    });

    test('FR-080 restoreItem returns Left when data source throws', () async {
      final item = ShoppingItem(
        id: 'item-1',
        listId: 'list-1',
        name: 'Apples',
        quantity: const Quantity(1000),
        unit: 'kg',
        unitPrice: const Money(200),
        isBought: false,
        createdAt: testNow,
        updatedAt: testNow,
      );

      when(() => mockDataSource.restoreItem(any(), any()))
          .thenThrow(SqliteException(13, 'disk full'));

      final result = await repository.restoreItem(item);
      expect(result, const Left(StorageFullFailure()));
    });

    test('FR-080 setBought sets bought flag and returns Right(unit)', () async {
      when(() => mockDataSource.setBought('item-1', true, any())).thenAnswer((_) async => 1);

      final result = await repository.setBought(id: 'item-1', isBought: true);
      expect(result, const Right(unit));
    });

    test('FR-080 setBought returns NotFoundFailure when row count is 0', () async {
      when(() => mockDataSource.setBought('item-1', true, any())).thenAnswer((_) async => 0);

      final result = await repository.setBought(id: 'item-1', isBought: true);
      expect(result, const Left(NotFoundFailure()));
    });

    test('FR-080 setBought returns Left when data source throws', () async {
      when(() => mockDataSource.setBought('item-1', true, any()))
          .thenThrow(SqliteException(1, 'db err'));

      final result = await repository.setBought(id: 'item-1', isBought: true);
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 itemCount returns Right(count)', () async {
      when(() => mockDataSource.itemCount('list-1')).thenAnswer((_) async => 10);

      final result = await repository.itemCount('list-1');
      expect(result, const Right(10));
    });

    test('FR-080 itemCount returns Left when data source throws', () async {
      when(() => mockDataSource.itemCount('list-1')).thenThrow(SqliteException(1, 'db err'));

      final result = await repository.itemCount('list-1');
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 hasDuplicateName returns Right(bool)', () async {
      when(() => mockDataSource.hasDuplicateName('list-1', 'apples', null))
          .thenAnswer((_) async => true);

      final result = await repository.hasDuplicateName(
        listId: 'list-1',
        name: 'apples',
      );
      expect(result, const Right(true));
    });

    test('FR-080 hasDuplicateName returns Left when data source throws', () async {
      when(() => mockDataSource.hasDuplicateName('list-1', 'apples', null))
          .thenThrow(SqliteException(1, 'db err'));

      final result = await repository.hasDuplicateName(
        listId: 'list-1',
        name: 'apples',
      );
      expect(result, const Left(DatabaseFailure('db err')));
    });
  });
}
