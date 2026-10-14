import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/theme/app_theme.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  testWidgets('MarketListApp renders placeholder screen with orange primary',
      (WidgetTester tester) async {
    final mockSettingsCubit = MockSettingsCubit();
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

    await tester.pumpWidget(MarketListApp(settingsCubit: mockSettingsCubit));
    await tester.pumpAndSettle();

    expect(find.text('Market List'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    final scaffold = tester.firstWidget<Scaffold>(find.byType(Scaffold));
    final appBar = scaffold.appBar as AppBar?;
    expect(appBar, isNotNull);
    expect(appBar!.backgroundColor, AppTheme.lightPrimary);
  });
}
