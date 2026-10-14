import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/create_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/duplicate_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/watch_lists.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';

class MockWatchLists extends Mock implements WatchLists {}

class MockCreateList extends Mock implements CreateList {}

class MockRenameList extends Mock implements RenameList {}

class MockSetListCurrency extends Mock implements SetListCurrency {}

class MockDeleteList extends Mock implements DeleteList {}

class MockDuplicateList extends Mock implements DuplicateList {}

void main() {
  late MockWatchLists mockWatchLists;
  late MockCreateList mockCreateList;
  late MockRenameList mockRenameList;
  late MockSetListCurrency mockSetListCurrency;
  late MockDeleteList mockDeleteList;
  late MockDuplicateList mockDuplicateList;
  late StreamController<Either<Failure, List<ListSummary>>> streamController;

  final testShoppingList = ShoppingList(
    id: 'list-1',
    name: 'Market list',
    currency: CurrencyCode.ngn,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  late final testSummary = ListSummary(
    list: testShoppingList,
    itemCount: 3,
    total: const Money(150000),
  );

  final testNewShoppingList = ShoppingList(
    id: 'list-new',
    name: 'New list',
    currency: CurrencyCode.ngn,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const CreateListParams(name: '', currency: CurrencyCode.usd),
    );
    registerFallbackValue(
      const RenameListParams(listId: '', name: ''),
    );
    registerFallbackValue(
      const SetListCurrencyParams(listId: '', currency: CurrencyCode.usd),
    );
  });

  setUp(() {
    mockWatchLists = MockWatchLists();
    mockCreateList = MockCreateList();
    mockRenameList = MockRenameList();
    mockSetListCurrency = MockSetListCurrency();
    mockDeleteList = MockDeleteList();
    mockDuplicateList = MockDuplicateList();
    streamController =
        StreamController<Either<Failure, List<ListSummary>>>.broadcast();

    when(() => mockWatchLists(any()))
        .thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  ListsCubit buildCubit() {
    return ListsCubit(
      watchLists: mockWatchLists,
      createList: mockCreateList,
      renameList: mockRenameList,
      setListCurrency: mockSetListCurrency,
      deleteList: mockDeleteList,
      duplicateList: mockDuplicateList,
    );
  }

  group('ListsCubit', () {
    test('initial state is loading with empty lists', () {
      final cubit = buildCubit();
      expect(cubit.state, const ListsState.initial());
      expect(cubit.state.status, ListsStatus.loading);
      expect(cubit.state.isEmpty, isFalse);
      cubit.close();
    });

    blocTest<ListsCubit, ListsState>(
      'FR-001 watch emits success when stream yields Right',
      build: buildCubit,
      act: (cubit) {
        cubit.watch();
        streamController.add(Right([testSummary]));
      },
      expect: () => [
        const ListsState(status: ListsStatus.loading),
        ListsState(
          status: ListsStatus.success,
          lists: [testSummary],
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-001 watch emits failure when stream yields Left',
      build: buildCubit,
      act: (cubit) {
        cubit.watch();
        streamController.add(const Left(DatabaseFailure('fail')));
      },
      expect: () => [
        const ListsState(status: ListsStatus.loading),
        const ListsState(
          status: ListsStatus.failure,
          message: FailureMessages.couldNotLoadLists,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'retry triggers watch again',
      build: buildCubit,
      act: (cubit) {
        cubit.retry();
        streamController.add(Right([testSummary]));
      },
      expect: () => [
        const ListsState(status: ListsStatus.loading),
        ListsState(
          status: ListsStatus.success,
          lists: [testSummary],
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-002 createList success sets createdListId',
      build: () {
        when(
          () => mockCreateList(
            const CreateListParams(
              name: 'New list',
              currency: CurrencyCode.ngn,
            ),
          ),
        ).thenAnswer((_) async => Right(testNewShoppingList));
        return buildCubit();
      },
      act: (cubit) => cubit.createList('New list', CurrencyCode.ngn),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          createdListId: 'list-new',
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-002 createList failure sets mapped message',
      build: () {
        when(
          () => mockCreateList(any()),
        ).thenAnswer(
          (_) async => const Left(LimitFailure(LimitKind.lists)),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.createList('New list', CurrencyCode.ngn),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          message: FailureMessages.listsLimitReached,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-003 renameList failure sets message',
      build: () {
        when(() => mockRenameList(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure()),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.renameList('list-1', 'Renamed'),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          message: FailureMessages.databaseErrorSave,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-007 setCurrency failure sets message',
      build: () {
        when(() => mockSetListCurrency(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure()),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.setCurrency('list-1', CurrencyCode.usd),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          message: FailureMessages.databaseErrorSave,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-005 deleteList failure sets message',
      build: () {
        when(() => mockDeleteList(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure()),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.deleteList('list-1'),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          message: FailureMessages.databaseErrorSave,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'FR-006 duplicateList failure sets message',
      build: () {
        when(() => mockDuplicateList(any())).thenAnswer(
          (_) async => const Left(LimitFailure(LimitKind.lists)),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.duplicateList('list-1'),
      expect: () => [
        const ListsState(
          status: ListsStatus.loading,
          message: FailureMessages.listsLimitReached,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'messageHandled clears message',
      build: buildCubit,
      seed: () => const ListsState(
        status: ListsStatus.success,
        message: 'Something went wrong',
      ),
      act: (cubit) => cubit.messageHandled(),
      expect: () => [
        const ListsState(
          status: ListsStatus.success,
          message: null,
        ),
      ],
    );

    blocTest<ListsCubit, ListsState>(
      'createdListHandled clears createdListId',
      build: buildCubit,
      seed: () => const ListsState(
        status: ListsStatus.success,
        createdListId: 'list-123',
      ),
      act: (cubit) => cubit.createdListHandled(),
      expect: () => [
        const ListsState(
          status: ListsStatus.success,
          createdListId: null,
        ),
      ],
    );
  });
}
