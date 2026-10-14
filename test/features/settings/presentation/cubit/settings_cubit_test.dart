import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/usecases/complete_onboarding.dart';
import 'package:market_list/features/settings/domain/usecases/ensure_settings.dart';
import 'package:market_list/features/settings/domain/usecases/set_default_currency.dart';
import 'package:market_list/features/settings/domain/usecases/set_theme_mode.dart';
import 'package:market_list/features/settings/domain/usecases/watch_settings.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockEnsureSettings extends Mock implements EnsureSettings {}

class MockWatchSettings extends Mock implements WatchSettings {}

class MockSetDefaultCurrency extends Mock implements SetDefaultCurrency {}

class MockSetThemeMode extends Mock implements SetThemeMode {}

class MockCompleteOnboarding extends Mock implements CompleteOnboarding {}

void main() {
  late MockEnsureSettings mockEnsureSettings;
  late MockWatchSettings mockWatchSettings;
  late MockSetDefaultCurrency mockSetDefaultCurrency;
  late MockSetThemeMode mockSetThemeMode;
  late MockCompleteOnboarding mockCompleteOnboarding;
  late StreamController<Either<Failure, AppSettings>> settingsStreamController;

  final testSettingsOnboardingFalse = const AppSettings(
    defaultCurrency: CurrencyCode.ngn,
    themeMode: AppThemeMode.system,
    onboardingDone: false,
  );

  final testSettingsOnboardingTrue = const AppSettings(
    defaultCurrency: CurrencyCode.ngn,
    themeMode: AppThemeMode.system,
    onboardingDone: true,
  );

  final testShoppingList = ShoppingList(
    id: 'first-list-id',
    name: 'Market list',
    currency: CurrencyCode.ngn,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockEnsureSettings = MockEnsureSettings();
    mockWatchSettings = MockWatchSettings();
    mockSetDefaultCurrency = MockSetDefaultCurrency();
    mockSetThemeMode = MockSetThemeMode();
    mockCompleteOnboarding = MockCompleteOnboarding();
    settingsStreamController =
        StreamController<Either<Failure, AppSettings>>.broadcast();

    when(() => mockWatchSettings(any()))
        .thenAnswer((_) => settingsStreamController.stream);
  });

  tearDown(() {
    settingsStreamController.close();
  });

  SettingsCubit buildCubit() {
    return SettingsCubit(
      ensureSettings: mockEnsureSettings,
      watchSettings: mockWatchSettings,
      setDefaultCurrency: mockSetDefaultCurrency,
      setThemeMode: mockSetThemeMode,
      completeOnboarding: mockCompleteOnboarding,
    );
  }

  group('SettingsCubit', () {
    test('initial state is SettingsState.initial() with status loading', () {
      final cubit = buildCubit();
      expect(cubit.state, const SettingsState.initial());
      expect(cubit.state.status, SettingsStatus.loading);
      cubit.close();
    });

    blocTest<SettingsCubit, SettingsState>(
      'FR-092 start with onboarding false goes to needsOnboarding',
      build: () {
        when(() => mockEnsureSettings('NG')).thenAnswer(
          (_) async => Right(
            EnsureSettingsResult(
              settings: testSettingsOnboardingFalse,
              suggestedCurrency: CurrencyCode.ngn,
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start('NG'),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.needsOnboarding,
          settings: testSettingsOnboardingFalse,
          suggestedCurrency: CurrencyCode.ngn,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-090 start with onboarding true goes to loaded and subscribes to watchSettings',
      build: () {
        when(() => mockEnsureSettings(null)).thenAnswer(
          (_) async => Right(
            EnsureSettingsResult(
              settings: testSettingsOnboardingTrue,
              suggestedCurrency: CurrencyCode.usd,
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          suggestedCurrency: CurrencyCode.usd,
        ),
      ],
      verify: (_) {
        verify(() => mockWatchSettings(const NoParams())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'start with failure goes to status failure with message',
      build: () {
        when(() => mockEnsureSettings(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('fail')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.start(),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.failure,
          message: FailureMessages.databaseCannotOpen,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-092 completeOnboarding success sets loaded and firstListId',
      build: () {
        when(() => mockCompleteOnboarding(CurrencyCode.ngn)).thenAnswer(
          (_) async => Right(testShoppingList),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.needsOnboarding,
        settings: testSettingsOnboardingFalse,
        suggestedCurrency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.completeOnboarding(CurrencyCode.ngn),
      expect: () => [
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingFalse,
          suggestedCurrency: CurrencyCode.ngn,
          firstListId: 'first-list-id',
        ),
      ],
      verify: (_) {
        verify(() => mockWatchSettings(const NoParams())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-092 completeOnboarding failure sets message and stays needsOnboarding',
      build: () {
        when(() => mockCompleteOnboarding(CurrencyCode.ngn)).thenAnswer(
          (_) async => const Left(DatabaseFailure('fail')),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.needsOnboarding,
        settings: testSettingsOnboardingFalse,
        suggestedCurrency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.completeOnboarding(CurrencyCode.ngn),
      expect: () => [
        SettingsState(
          status: SettingsStatus.needsOnboarding,
          settings: testSettingsOnboardingFalse,
          suggestedCurrency: CurrencyCode.ngn,
          message: FailureMessages.firstRunSaveFailed,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-090 setDefaultCurrency success delegates to usecase',
      build: () {
        when(() => mockSetDefaultCurrency(CurrencyCode.eur)).thenAnswer(
          (_) async => const Right(unit),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
      ),
      act: (cubit) => cubit.setDefaultCurrency(CurrencyCode.eur),
      expect: () => [],
      verify: (_) {
        verify(() => mockSetDefaultCurrency(CurrencyCode.eur)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-090 setDefaultCurrency failure keeps loaded and sets message',
      build: () {
        when(() => mockSetDefaultCurrency(CurrencyCode.eur)).thenAnswer(
          (_) async => const Left(DatabaseFailure('fail')),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
      ),
      act: (cubit) => cubit.setDefaultCurrency(CurrencyCode.eur),
      expect: () => [
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          message: FailureMessages.settingSaveFailed,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-091 setThemeMode success delegates to usecase',
      build: () {
        when(() => mockSetThemeMode(AppThemeMode.dark)).thenAnswer(
          (_) async => const Right(unit),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
      ),
      act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
      expect: () => [],
      verify: (_) {
        verify(() => mockSetThemeMode(AppThemeMode.dark)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'FR-091 setThemeMode failure keeps loaded and sets message',
      build: () {
        when(() => mockSetThemeMode(AppThemeMode.dark)).thenAnswer(
          (_) async => const Left(DatabaseFailure('fail')),
        );
        return buildCubit();
      },
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
      ),
      act: (cubit) => cubit.setThemeMode(AppThemeMode.dark),
      expect: () => [
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          message: FailureMessages.settingSaveFailed,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'messageHandled clears message',
      build: buildCubit,
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
        message: FailureMessages.settingSaveFailed,
      ),
      act: (cubit) => cubit.messageHandled(),
      expect: () => [
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          message: null,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'firstListHandled clears firstListId',
      build: buildCubit,
      seed: () => SettingsState(
        status: SettingsStatus.loaded,
        settings: testSettingsOnboardingTrue,
        firstListId: 'first-list-id',
      ),
      act: (cubit) => cubit.firstListHandled(),
      expect: () => [
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          firstListId: null,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'stream update from watchSettings emits new settings in state',
      build: () {
        when(() => mockEnsureSettings(null)).thenAnswer(
          (_) async => Right(
            EnsureSettingsResult(
              settings: testSettingsOnboardingTrue,
              suggestedCurrency: CurrencyCode.usd,
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.start();
        final updatedSettings = testSettingsOnboardingTrue.copyWith(
          themeMode: AppThemeMode.dark,
        );
        settingsStreamController.add(Right(updatedSettings));
      },
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue,
          suggestedCurrency: CurrencyCode.usd,
        ),
        SettingsState(
          status: SettingsStatus.loaded,
          settings: testSettingsOnboardingTrue.copyWith(
            themeMode: AppThemeMode.dark,
          ),
          suggestedCurrency: CurrencyCode.usd,
        ),
      ],
    );
  });
}
