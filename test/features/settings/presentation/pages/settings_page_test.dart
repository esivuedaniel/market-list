import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/settings/presentation/pages/settings_page.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late MockSettingsCubit mockSettingsCubit;

  const testSettings = AppSettings(
    defaultCurrency: CurrencyCode.ngn,
    themeMode: AppThemeMode.system,
    onboardingDone: true,
  );

  setUpAll(() {
    registerFallbackValue(CurrencyCode.usd);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
  });

  Widget buildTestableWidget({
    SettingsState state = const SettingsState(
      status: SettingsStatus.loaded,
      settings: testSettings,
    ),
  }) {
    when(() => mockSettingsCubit.state).thenReturn(state);
    return MaterialApp(
      home: BlocProvider<SettingsCubit>.value(
        value: mockSettingsCubit,
        child: const SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders app bar, currency tile, theme tile, and about section',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Default currency'), findsOneWidget);
      expect(find.text('Applies to new lists only.'), findsOneWidget);
      expect(find.text('₦  NGN'), findsOneWidget);

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      expect(find.text('About'), findsOneWidget);
      expect(
        find.text(
          'Your lists live on this phone. Phone backup may restore '
          'them on a new phone. The app collects no data.',
        ),
        findsOneWidget,
      );
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('FR-090 changes default currency via dialog', (tester) async {
      when(() => mockSettingsCubit.setDefaultCurrency(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Default currency'));
      await tester.pumpAndSettle();

      expect(find.text('€  EUR'), findsOneWidget);
      await tester.tap(find.text('€  EUR'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsCubit.setDefaultCurrency(CurrencyCode.eur))
          .called(1);
    });

    testWidgets('FR-091 changes theme mode via dialog', (tester) async {
      when(() => mockSettingsCubit.setThemeMode(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Dark'), findsOneWidget);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsCubit.setThemeMode(AppThemeMode.dark))
          .called(1);
    });

    testWidgets('shows snackbar when message is emitted and clears it',
        (tester) async {
      whenListen(
        mockSettingsCubit,
        Stream.fromIterable([
          const SettingsState(
            status: SettingsStatus.loaded,
            settings: testSettings,
            message: 'Could not save your setting.',
          ),
        ]),
        initialState: const SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettings,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Could not save your setting.'), findsOneWidget);
      verify(() => mockSettingsCubit.messageHandled()).called(1);
    });

    testWidgets('NFR-009 and NFR-011 renders without overflow on 320x568 dp screen and text scale 2.0',
        (tester) async {
      when(() => mockSettingsCubit.state).thenReturn(
        const SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettings,
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
            child: BlocProvider<SettingsCubit>.value(
              value: mockSettingsCubit,
              child: const SettingsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
