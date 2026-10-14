import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/widgets/empty_state.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_bloc.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_event.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_state.dart';
import 'package:market_list/features/items/presentation/pages/list_detail_page.dart';
import 'package:market_list/features/items/presentation/widgets/item_tile.dart';
import 'package:market_list/features/items/presentation/widgets/summary_card.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:mocktail/mocktail.dart';

class MockListDetailBloc extends MockBloc<ListDetailEvent, ListDetailState>
    implements ListDetailBloc {}

void main() {
  late MockListDetailBloc mockBloc;

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

  final emptyDetail = ListDetail(
    list: testList,
    items: const [],
  );

  setUpAll(() {
    registerFallbackValue(const ListDetailStarted('list-1'));
    registerFallbackValue(const ListDetailRetried());
    registerFallbackValue(const ItemBoughtToggled(itemId: '1', isBought: true));
    registerFallbackValue(const ItemDeleted('1'));
    registerFallbackValue(ItemRestoreRequested(testItem));
    registerFallbackValue(const DeletedItemHandled());
    registerFallbackValue(const SearchQueryChanged(''));
    registerFallbackValue(const ListRenamed(''));
    registerFallbackValue(const ListCurrencyChanged(CurrencyCode.usd));
    registerFallbackValue(const ListDeleted());
    registerFallbackValue(const MessageHandled());
  });

  setUp(() {
    mockBloc = MockListDetailBloc();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider<ListDetailBloc>.value(
        value: mockBloc,
        child: const ListDetailPage(),
      ),
    );
  }

  group('ListDetailPage', () {
    testWidgets('shows LoadingView when status is loading', (tester) async {
      when(() => mockBloc.state)
          .thenReturn(const ListDetailState(status: ListDetailStatus.loading));

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('shows ErrorView when status is failure and retries', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ListDetailState(
          status: ListDetailStatus.failure,
          message: FailureMessages.couldNotLoadList,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text(FailureMessages.couldNotLoadList), findsOneWidget);

      await tester.tap(find.text('Retry'));
      verify(() => mockBloc.add(const ListDetailRetried())).called(1);
    });

    testWidgets('FR-021 shows empty state when list has no items', (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: emptyDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(SummaryCard), findsOneWidget);
      expect(find.text('₦0.00'), findsOneWidget);
      expect(find.text('0 of 0 bought'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No items yet. Tap Add item to start.'), findsOneWidget);

      // FR-072: Share button disabled with tooltip
      final shareButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.share),
      );
      expect(shareButton.onPressed, isNull);
      expect(shareButton.tooltip, FailureMessages.emptyListShareTooltip);
    });

    testWidgets('FR-020 shows items and SummaryCard when status is success',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(SummaryCard), findsOneWidget);
      expect(find.text('₦3,750.00'), findsWidgets);
      expect(find.byType(ItemTile), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);

      final shareButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.share),
      );
      expect(shareButton.onPressed, isNotNull);
      expect(shareButton.tooltip, 'Share list');
    });

    testWidgets('FR-022 search toggles textfield and dispatches SearchQueryChanged',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tom');
      verify(() => mockBloc.add(const SearchQueryChanged('tom'))).called(1);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      verify(() => mockBloc.add(const SearchQueryChanged(''))).called(1);
    });

    testWidgets('FR-022 search with no match shows empty message and keeps total',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
          query: 'xyz',
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(SummaryCard), findsOneWidget);
      expect(find.text('₦3,750.00'), findsOneWidget);
      expect(find.byType(ItemTile), findsNothing);
      expect(find.text(FailureMessages.noItemsMatch('xyz')), findsOneWidget);
    });

    testWidgets('FR-041 Undo snackbar shows when deletedItem is emitted and calls restore',
        (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          ListDetailState(
            status: ListDetailStatus.success,
            detail: emptyDetail,
            deletedItem: testItem,
          ),
        ]),
        initialState: ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Item deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      verify(() => mockBloc.add(ItemRestoreRequested(testItem))).called(1);
    });

    testWidgets('FR-014 Add item blocks navigation at 500 items', (tester) async {
      final items500 = List.generate(
        500,
        (i) => testItem.copyWith(id: 'item-$i'),
      );
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: ListDetail(list: testList, items: items500),
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.text(FailureMessages.listItemsLimitReached), findsOneWidget);
    });

    testWidgets('FR-003 Rename list option opens dialog and dispatches ListRenamed',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byTooltip('List options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename list'));
      await tester.pumpAndSettle();

      expect(find.text('Rename list'), findsWidgets);
      await tester.enterText(find.byType(TextFormField), 'Sunday market');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const ListRenamed('Sunday market'))).called(1);
    });

    testWidgets('FR-007 Change currency option opens dialog and dispatches ListCurrencyChanged',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byTooltip('List options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change currency'));
      await tester.pumpAndSettle();

      expect(find.text('Prices are not converted.'), findsOneWidget);
      await tester.tap(find.text(r'$ (USD)'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const ListCurrencyChanged(CurrencyCode.usd))).called(1);
    });

    testWidgets('FR-004 Delete list option opens confirmation and dispatches ListDeleted',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byTooltip('List options'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete list'));
      await tester.pumpAndSettle();

      expect(find.text('Delete list?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const ListDeleted())).called(1);
    });

    testWidgets('shows snackbar when message is emitted and clears it', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable([
          ListDetailState(
            status: ListDetailStatus.success,
            detail: testDetail,
            message: 'Error saving item',
          ),
        ]),
        initialState: ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Error saving item'), findsOneWidget);
      verify(() => mockBloc.add(const MessageHandled())).called(1);
    });

    testWidgets('NFR-009 and NFR-011 renders without overflow on 320x568 dp screen and text scale 2.0',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(320, 568),
            ),
            child: BlocProvider<ListDetailBloc>.value(
              value: mockBloc,
              child: const ListDetailPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Market list'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);
    });

    testWidgets('NFR-012 app bar icon buttons have tooltips and semantics',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
        ListDetailState(
          status: ListDetailStatus.success,
          detail: testDetail,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Share list'), findsOneWidget);
      expect(find.byTooltip('List options'), findsOneWidget);
    });
  });
}
