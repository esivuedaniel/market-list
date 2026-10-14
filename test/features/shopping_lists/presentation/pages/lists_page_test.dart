import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/core/widgets/empty_state.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';
import 'package:market_list/features/shopping_lists/presentation/pages/lists_page.dart';

class MockListsCubit extends MockCubit<ListsState> implements ListsCubit {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late MockListsCubit mockListsCubit;
  late MockSettingsCubit mockSettingsCubit;

  final testSummary = ListSummary(
    list: ShoppingList(
      id: 'list-1',
      name: 'Sunday market',
      currency: CurrencyCode.ngn,
      createdAt: DateTime.utc(2026, 10, 12),
      updatedAt: DateTime.utc(2026, 10, 12),
    ),
    itemCount: 5,
    total: const Money(4935000),
  );

  setUpAll(() {
    registerFallbackValue(CurrencyCode.usd);
  });

  setUp(() {
    mockListsCubit = MockListsCubit();
    mockSettingsCubit = MockSettingsCubit();

    when(() => mockSettingsCubit.state).thenReturn(
      const SettingsState(
        status: SettingsStatus.loaded,
        settings: AppSettings(
          defaultCurrency: CurrencyCode.usd,
          themeMode: AppThemeMode.system,
          onboardingDone: true,
        ),
      ),
    );
  });

  Widget buildTestableWidget({
    ListsState state = const ListsState(status: ListsStatus.loading),
  }) {
    when(() => mockListsCubit.state).thenReturn(state);
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == AppRouter.settings) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Settings Screen')),
          );
        }
        if (settings.name == AppRouter.listDetail) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Detail Screen')),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<ListsCubit>.value(value: mockListsCubit),
              BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
            ],
            child: const ListsPage(),
          ),
        );
      },
    );
  }

  group('ListsPage', () {
    testWidgets('shows LoadingView when status is loading', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          state: const ListsState(status: ListsStatus.loading),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('shows ErrorView when status is failure and retries',
        (tester) async {
      when(() => mockListsCubit.retry()).thenReturn(null);

      await tester.pumpWidget(
        buildTestableWidget(
          state: const ListsState(
            status: ListsStatus.failure,
            message: 'Could not load your lists.',
          ),
        ),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Could not load your lists.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      verify(() => mockListsCubit.retry()).called(1);
    });

    testWidgets('shows EmptyState when lists is empty and status success',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          state: const ListsState(
            status: ListsStatus.success,
            lists: [],
          ),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No lists yet'), findsOneWidget);
      expect(find.text('Create your first list'), findsOneWidget);
    });

    testWidgets('FR-001 shows list of cards on success with data',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      expect(find.text('My Lists'), findsOneWidget);
      expect(find.text('Sunday market'), findsOneWidget);
      expect(find.text('5 items • Updated 12 Oct 2026'), findsOneWidget);
      expect(find.text('₦49,350.00'), findsOneWidget);
    });

    testWidgets('tapping card navigates to /list', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.text('Sunday market'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Screen'), findsOneWidget);
    });

    testWidgets('tapping settings icon navigates to /settings', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('FR-002 FAB opens create dialog and creates list',
        (tester) async {
      when(() => mockListsCubit.createList(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();

      expect(find.text('New list'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'Party groceries');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      verify(() => mockListsCubit.createList('Party groceries', CurrencyCode.usd))
          .called(1);
    });

    testWidgets('FR-003 rename option opens dialog and calls renameList',
        (tester) async {
      when(() => mockListsCubit.renameList(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename list'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Saturday market');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockListsCubit.renameList('list-1', 'Saturday market'))
          .called(1);
    });

    testWidgets('FR-007 currency option opens dialog and calls setCurrency',
        (tester) async {
      when(() => mockListsCubit.setCurrency(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change currency'));
      await tester.pumpAndSettle();

      expect(find.text('Change currency'), findsOneWidget);
      await tester.tap(find.text('€  EUR'));
      await tester.pumpAndSettle();

      verify(() => mockListsCubit.setCurrency('list-1', CurrencyCode.eur))
          .called(1);
    });

    testWidgets('FR-006 duplicate option calls duplicateList', (tester) async {
      when(() => mockListsCubit.duplicateList(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate'));
      await tester.pumpAndSettle();

      verify(() => mockListsCubit.duplicateList('list-1')).called(1);
    });

    testWidgets('FR-005 delete option opens confirmation and calls deleteList',
        (tester) async {
      when(() => mockListsCubit.deleteList(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: ListsState(
            status: ListsStatus.success,
            lists: [testSummary],
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete list'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(() => mockListsCubit.deleteList('list-1')).called(1);
    });

    testWidgets('shows snackbar when message is emitted and clears it',
        (tester) async {
      whenListen(
        mockListsCubit,
        Stream.fromIterable([
          const ListsState(
            status: ListsStatus.success,
            message: 'Could not save your list.',
          ),
        ]),
        initialState: const ListsState(status: ListsStatus.success),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Could not save your list.'), findsOneWidget);
      verify(() => mockListsCubit.messageHandled()).called(1);
    });

    testWidgets('navigates to /list when createdListId is emitted',
        (tester) async {
      whenListen(
        mockListsCubit,
        Stream.fromIterable([
          const ListsState(
            status: ListsStatus.success,
            createdListId: 'new-list-id',
          ),
        ]),
        initialState: const ListsState(status: ListsStatus.success),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Detail Screen'), findsOneWidget);
      verify(() => mockListsCubit.createdListHandled()).called(1);
    });
  });
}
