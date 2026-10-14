import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';
import 'package:market_list/features/items/domain/usecases/restore_item.dart';
import 'package:market_list/features/items/domain/usecases/set_item_bought.dart';
import 'package:market_list/features/items/domain/usecases/watch_list_detail.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_bloc.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_event.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_state.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchListDetail extends Mock implements WatchListDetail {}
class MockSetItemBought extends Mock implements SetItemBought {}
class MockDeleteItem extends Mock implements DeleteItem {}
class MockRestoreItem extends Mock implements RestoreItem {}
class MockRenameList extends Mock implements RenameList {}
class MockSetListCurrency extends Mock implements SetListCurrency {}
class MockDeleteList extends Mock implements DeleteList {}
class MockAddItem extends Mock implements AddItem {}

void main() {
  late MockWatchListDetail mockWatchListDetail;
  late MockSetItemBought mockSetItemBought;
  late MockDeleteItem mockDeleteItem;
  late MockRestoreItem mockRestoreItem;
  late MockRenameList mockRenameList;
  late MockSetListCurrency mockSetListCurrency;
  late MockDeleteList mockDeleteList;
  late MockAddItem mockAddItem;

  final testDate = DateTime.utc(2026, 10, 14);
  final testList = ShoppingList(
    id: 'list-1',
    name: 'Market list',
    currency: CurrencyCode.ngn,
    createdAt: testDate,
    updatedAt: testDate,
  );

  final testItem = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity.fromMilli(2500),
    unit: 'kg',
    unitPrice: const Money.fromMinor(150000),
    isBought: false,
    createdAt: testDate,
    updatedAt: testDate,
  );

  final testDetail = ListDetail(
    list: testList,
    items: [testItem],
  );

  setUpAll(() {
    registerFallbackValue(const SetItemBoughtParams(itemId: 'id', isBought: false));
    registerFallbackValue(testItem);
    registerFallbackValue(const RenameListParams(listId: 'id', name: 'name'));
    registerFallbackValue(const SetListCurrencyParams(listId: 'id', currency: CurrencyCode.usd));
    registerFallbackValue(AddItemParams(
      listId: 'id',
      draft: ItemDraft(
        name: testItem.name,
        quantity: testItem.quantity,
        unit: testItem.unit,
        unitPrice: testItem.unitPrice,
      ),
    ));
  });

  setUp(() {
    mockWatchListDetail = MockWatchListDetail();
    mockSetItemBought = MockSetItemBought();
    mockDeleteItem = MockDeleteItem();
    mockRestoreItem = MockRestoreItem();
    mockRenameList = MockRenameList();
    mockSetListCurrency = MockSetListCurrency();
    mockDeleteList = MockDeleteList();
    mockAddItem = MockAddItem();
  });

  ListDetailBloc buildBloc() {
    return ListDetailBloc(
      watchListDetail: mockWatchListDetail,
      setItemBought: mockSetItemBought,
      deleteItem: mockDeleteItem,
      restoreItem: mockRestoreItem,
      renameList: mockRenameList,
      setListCurrency: mockSetListCurrency,
      deleteList: mockDeleteList,
      addItem: mockAddItem,
    );
  }

  group('ListDetailBloc', () {
    test('initial state is loading with empty defaults', () {
      final bloc = buildBloc();
      expect(bloc.state.status, ListDetailStatus.loading);
      expect(bloc.state.detail, isNull);
      expect(bloc.state.query, '');
      expect(bloc.state.deletedItem, isNull);
      expect(bloc.state.message, isNull);
      expect(bloc.state.listRemoved, isFalse);
    });

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-020 ListDetailStarted emits [loading, success] on Right',
      build: () {
        when(() => mockWatchListDetail('list-1'))
            .thenAnswer((_) => Stream.value(Right(testDetail)));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ListDetailStarted('list-1')),
      expect: () => [
        const ListDetailState(status: ListDetailStatus.loading),
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-023 ListDetailStarted emits [loading, failure] on Left',
      build: () {
        when(() => mockWatchListDetail('list-1'))
            .thenAnswer((_) => Stream.value(const Left(DatabaseFailure())));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ListDetailStarted('list-1')),
      expect: () => [
        const ListDetailState(status: ListDetailStatus.loading),
        const ListDetailState(
          status: ListDetailStatus.failure,
          message: FailureMessages.couldNotLoadList,
        ),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-023 ListDetailRetried restarts subscription',
      build: () {
        when(() => mockWatchListDetail('list-1'))
            .thenAnswer((_) => Stream.value(Right(testDetail)));
        return buildBloc();
      },
      seed: () => const ListDetailState(status: ListDetailStatus.failure),
      act: (bloc) async {
        bloc.add(const ListDetailStarted('list-1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ListDetailRetried());
      },
      expect: () => [
        const ListDetailState(status: ListDetailStatus.loading),
        ListDetailState(status: ListDetailStatus.success, detail: testDetail),
        ListDetailState(status: ListDetailStatus.loading, detail: testDetail),
        ListDetailState(status: ListDetailStatus.success, detail: testDetail),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-050 ItemBoughtToggled calls SetItemBought and emits message on failure',
      build: () {
        when(() => mockSetItemBought(any()))
            .thenAnswer((_) async => const Left(DatabaseFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ItemBoughtToggled(itemId: 'item-1', isBought: true)),
      expect: () => [
        const ListDetailState(message: FailureMessages.databaseErrorSave),
      ],
      verify: (_) {
        verify(() => mockSetItemBought(const SetItemBoughtParams(
          itemId: 'item-1',
          isBought: true,
        ))).called(1);
      },
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-040 ItemDeleted sets deletedItem on success',
      build: () {
        when(() => mockDeleteItem('item-1'))
            .thenAnswer((_) async => Right(testItem));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ItemDeleted('item-1')),
      expect: () => [
        ListDetailState(deletedItem: testItem),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-040 ItemDeleted sets message on failure',
      build: () {
        when(() => mockDeleteItem('item-1'))
            .thenAnswer((_) async => const Left(DatabaseFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ItemDeleted('item-1')),
      expect: () => [
        const ListDetailState(message: FailureMessages.databaseErrorSave),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-041 ItemRestoreRequested clears deletedItem and calls restoreItem',
      build: () {
        when(() => mockRestoreItem(testItem))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => ListDetailState(deletedItem: testItem),
      act: (bloc) => bloc.add(ItemRestoreRequested(testItem)),
      expect: () => [
        const ListDetailState(deletedItem: null),
      ],
      verify: (_) {
        verify(() => mockRestoreItem(testItem)).called(1);
      },
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-041 ItemRestoreRequested sets undoItemsLimitReached on LimitFailure',
      build: () {
        when(() => mockRestoreItem(testItem))
            .thenAnswer((_) async => const Left(LimitFailure(LimitKind.items)));
        return buildBloc();
      },
      seed: () => ListDetailState(deletedItem: testItem),
      act: (bloc) => bloc.add(ItemRestoreRequested(testItem)),
      expect: () => [
        const ListDetailState(deletedItem: null),
        const ListDetailState(
          deletedItem: null,
          message: FailureMessages.undoItemsLimitReached,
        ),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'DeletedItemHandled clears deletedItem',
      build: buildBloc,
      seed: () => ListDetailState(deletedItem: testItem),
      act: (bloc) => bloc.add(const DeletedItemHandled()),
      expect: () => [
        const ListDetailState(deletedItem: null),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-022 SearchQueryChanged updates query',
      build: buildBloc,
      act: (bloc) => bloc.add(const SearchQueryChanged('tom')),
      expect: () => [
        const ListDetailState(query: 'tom'),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-003 ListRenamed calls RenameList and sets message on failure',
      build: () {
        when(() => mockRenameList(any()))
            .thenAnswer((_) async => const Left(ValidationFailure('Enter a list name.')));
        return buildBloc();
      },
      seed: () => ListDetailState(detail: testDetail),
      act: (bloc) => bloc.add(const ListRenamed('')),
      expect: () => [
        ListDetailState(detail: testDetail, message: 'Enter a list name.'),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-007 ListCurrencyChanged calls SetListCurrency',
      build: () {
        when(() => mockSetListCurrency(any()))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => ListDetailState(detail: testDetail),
      act: (bloc) => bloc.add(const ListCurrencyChanged(CurrencyCode.usd)),
      verify: (_) {
        verify(() => mockSetListCurrency(const SetListCurrencyParams(
          listId: 'list-1',
          currency: CurrencyCode.usd,
        ))).called(1);
      },
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'FR-004 ListDeleted sets listRemoved to true on success',
      build: () {
        when(() => mockDeleteList('list-1'))
            .thenAnswer((_) async => const Right(unit));
        return buildBloc();
      },
      seed: () => ListDetailState(detail: testDetail),
      act: (bloc) => bloc.add(const ListDeleted()),
      expect: () => [
        ListDetailState(detail: testDetail, listRemoved: true),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'MessageHandled clears message',
      build: buildBloc,
      seed: () => const ListDetailState(message: 'Sample error'),
      act: (bloc) => bloc.add(const MessageHandled()),
      expect: () => [
        const ListDetailState(message: null),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'SeedSampleItems adds 5 items in debug mode',
      build: () {
        when(() => mockAddItem(any())).thenAnswer((_) async => Right(testItem));
        return buildBloc();
      },
      seed: () => ListDetailState(detail: testDetail),
      act: (bloc) => bloc.add(const SeedSampleItems()),
      verify: (_) {
        verify(() => mockAddItem(any())).called(5);
      },
    );
  });
}
