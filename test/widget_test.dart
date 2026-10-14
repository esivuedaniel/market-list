import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockListsCubit extends MockCubit<ListsState> implements ListsCubit {}

void main() {
  testWidgets('MarketListApp renders lists screen with app bar',
      (WidgetTester tester) async {
    final mockSettingsCubit = MockSettingsCubit();
    final mockListsCubit = MockListsCubit();
    when(() => mockSettingsCubit.state).thenReturn(
      const SettingsState(
        status: SettingsStatus.loaded,
        settings: AppSettings(
          defaultCurrency: CurrencyCode.usd,
          themeMode: AppThemeMode.light,
          onboardingDone: true,
        ),
      ),
    );
    when(() => mockListsCubit.state)
        .thenReturn(const ListsState(status: ListsStatus.success));
    when(() => mockListsCubit.watch()).thenAnswer((_) async {});

    if (getIt.isRegistered<ListsCubit>()) {
      getIt.unregister<ListsCubit>();
    }
    getIt.registerFactory<ListsCubit>(() => mockListsCubit);

    await tester.pumpWidget(MarketListApp(settingsCubit: mockSettingsCubit));
    await tester.pumpAndSettle();

    expect(find.text('My Lists'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    final scaffold = tester.firstWidget<Scaffold>(find.byType(Scaffold));
    final appBar = scaffold.appBar as AppBar?;
    expect(appBar, isNotNull);

    if (getIt.isRegistered<ListsCubit>()) {
      getIt.unregister<ListsCubit>();
    }
  });
}
