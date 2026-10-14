import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/features/settings/presentation/widgets/onboarding_sheet.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockListsCubit extends MockCubit<ListsState> implements ListsCubit {}

void main() {
  late MockSettingsCubit mockSettingsCubit;
  late MockListsCubit mockListsCubit;

  setUpAll(() {
    registerFallbackValue(CurrencyCode.usd);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    mockListsCubit = MockListsCubit();
    when(() => mockListsCubit.state)
        .thenReturn(const ListsState(status: ListsStatus.success));
    when(() => mockListsCubit.watch()).thenAnswer((_) async {});

    if (getIt.isRegistered<ListsCubit>()) {
      getIt.unregister<ListsCubit>();
    }
    getIt.registerFactory<ListsCubit>(() => mockListsCubit);
  });

  tearDown(() {
    if (getIt.isRegistered<ListsCubit>()) {
      getIt.unregister<ListsCubit>();
    }
  });

  group('MarketListApp', () {
    testWidgets('shows LoadingView when status is loading', (tester) async {
      when(() => mockSettingsCubit.state).thenReturn(
        const SettingsState(status: SettingsStatus.loading),
      );

      await tester.pumpWidget(
        MarketListApp(settingsCubit: mockSettingsCubit),
      );

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('shows ErrorView when status is failure and retries',
        (tester) async {
      when(() => mockSettingsCubit.state).thenReturn(
        const SettingsState(
          status: SettingsStatus.failure,
          message: 'Could not open your data. Close the app and try again.',
        ),
      );
      when(() => mockSettingsCubit.start(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        MarketListApp(settingsCubit: mockSettingsCubit),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('Could not open your data. Close the app and try again.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));
      verify(() => mockSettingsCubit.start()).called(1);
    });

    testWidgets('shows OnboardingSheet when status is needsOnboarding',
        (tester) async {
      when(() => mockSettingsCubit.state).thenReturn(
        const SettingsState(
          status: SettingsStatus.needsOnboarding,
          suggestedCurrency: CurrencyCode.ngn,
        ),
      );

      await tester.pumpWidget(
        MarketListApp(settingsCubit: mockSettingsCubit),
      );

      expect(find.byType(OnboardingSheet), findsOneWidget);
    });

    testWidgets('shows Lists screen when status is loaded', (tester) async {
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

      await tester.pumpWidget(
        MarketListApp(settingsCubit: mockSettingsCubit),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'My Lists'), findsOneWidget);
    });

    testWidgets('navigates to /list and calls firstListHandled when firstListId emitted',
        (tester) async {
      whenListen(
        mockSettingsCubit,
        Stream.fromIterable([
          const SettingsState(
            status: SettingsStatus.loaded,
            firstListId: 'list-123',
            settings: AppSettings(
              defaultCurrency: CurrencyCode.usd,
              themeMode: AppThemeMode.system,
              onboardingDone: true,
            ),
          ),
        ]),
        initialState: const SettingsState(
          status: SettingsStatus.loaded,
          settings: AppSettings(
            defaultCurrency: CurrencyCode.usd,
            themeMode: AppThemeMode.system,
            onboardingDone: true,
          ),
        ),
      );

      await tester.pumpWidget(
        MarketListApp(settingsCubit: mockSettingsCubit),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'List Detail'), findsOneWidget);
      verify(() => mockSettingsCubit.firstListHandled()).called(1);
    });
  });
}
