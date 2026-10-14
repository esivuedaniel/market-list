import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/settings/presentation/widgets/onboarding_sheet.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

void main() {
  late MockSettingsCubit mockSettingsCubit;

  setUpAll(() {
    registerFallbackValue(CurrencyCode.usd);
  });

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
  });

  Widget buildTestableWidget({
    SettingsState state = const SettingsState(
      status: SettingsStatus.needsOnboarding,
      suggestedCurrency: CurrencyCode.ngn,
    ),
  }) {
    when(() => mockSettingsCubit.state).thenReturn(state);
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<SettingsCubit>.value(
          value: mockSettingsCubit,
          child: const OnboardingSheet(),
        ),
      ),
    );
  }

  group('OnboardingSheet', () {
    testWidgets('FR-092 renders title, 7 currencies, and continue button',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Choose your currency'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      for (final code in CurrencyCode.values) {
        expect(find.text('${code.symbol}  ${code.code}'), findsOneWidget);
      }
    });

    testWidgets('FR-092 preselects suggested currency and taps continue',
        (tester) async {
      when(() => mockSettingsCubit.completeOnboarding(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: const SettingsState(
            status: SettingsStatus.needsOnboarding,
            suggestedCurrency: CurrencyCode.ngn,
          ),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsCubit.completeOnboarding(CurrencyCode.ngn))
          .called(1);
    });

    testWidgets('FR-092 selects a different currency before continue',
        (tester) async {
      when(() => mockSettingsCubit.completeOnboarding(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestableWidget(
          state: const SettingsState(
            status: SettingsStatus.needsOnboarding,
            suggestedCurrency: CurrencyCode.ngn,
          ),
        ),
      );

      await tester.tap(find.text('€  EUR'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verify(() => mockSettingsCubit.completeOnboarding(CurrencyCode.eur))
          .called(1);
    });

    testWidgets('shows snackbar when message is emitted and clears it',
        (tester) async {
      whenListen(
        mockSettingsCubit,
        Stream.fromIterable([
          const SettingsState(
            status: SettingsStatus.needsOnboarding,
            message: 'Something went wrong while saving. Try again.',
          ),
        ]),
        initialState: const SettingsState(
          status: SettingsStatus.needsOnboarding,
        ),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(
        find.text('Something went wrong while saving. Try again.'),
        findsOneWidget,
      );
      verify(() => mockSettingsCubit.messageHandled()).called(1);
    });

    testWidgets('does not overflow on 320x568 dp screen and text scale 2.0',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(2.0),
            size: Size(320, 568),
          ),
          child: buildTestableWidget(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
