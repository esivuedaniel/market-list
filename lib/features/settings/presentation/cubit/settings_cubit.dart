import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
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
import 'package:market_list/features/settings/presentation/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required EnsureSettings ensureSettings,
    required WatchSettings watchSettings,
    required SetDefaultCurrency setDefaultCurrency,
    required SetThemeMode setThemeMode,
    required CompleteOnboarding completeOnboarding,
  })  : _ensureSettings = ensureSettings,
        _watchSettings = watchSettings,
        _setDefaultCurrency = setDefaultCurrency,
        _setThemeMode = setThemeMode,
        _completeOnboarding = completeOnboarding,
        super(const SettingsState.initial());

  final EnsureSettings _ensureSettings;
  final WatchSettings _watchSettings;
  final SetDefaultCurrency _setDefaultCurrency;
  final SetThemeMode _setThemeMode;
  final CompleteOnboarding _completeOnboarding;

  StreamSubscription<Either<Failure, AppSettings>>? _settingsSubscription;

  Future<void> start([String? regionCode]) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await _ensureSettings(regionCode);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            message: FailureMessages.databaseCannotOpen,
          ),
        );
      },
      (data) {
        if (!data.settings.onboardingDone) {
          emit(
            state.copyWith(
              status: SettingsStatus.needsOnboarding,
              settings: data.settings,
              suggestedCurrency: data.suggestedCurrency,
            ),
          );
        } else {
          emit(
            state.copyWith(
              status: SettingsStatus.loaded,
              settings: data.settings,
              suggestedCurrency: data.suggestedCurrency,
            ),
          );
          _subscribeToSettings();
        }
      },
    );
  }

  Future<void> completeOnboarding(CurrencyCode currency) async {
    final result = await _completeOnboarding(currency);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: SettingsStatus.needsOnboarding,
            message: FailureMessages.firstRunSaveFailed,
          ),
        );
      },
      (list) {
        emit(
          state.copyWith(
            status: SettingsStatus.loaded,
            firstListId: list.id,
          ),
        );
        _subscribeToSettings();
      },
    );
  }

  Future<void> setDefaultCurrency(CurrencyCode currency) async {
    final result = await _setDefaultCurrency(currency);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: SettingsStatus.loaded,
            message: FailureMessages.settingSaveFailed,
          ),
        );
      },
      (_) {},
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final result = await _setThemeMode(mode);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: SettingsStatus.loaded,
            message: FailureMessages.settingSaveFailed,
          ),
        );
      },
      (_) {},
    );
  }

  void messageHandled() {
    emit(state.copyWith(clearMessage: true));
  }

  void firstListHandled() {
    emit(state.copyWith(clearFirstListId: true));
  }

  void _subscribeToSettings() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _watchSettings(const NoParams()).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (_) {},
          (settings) {
            emit(state.copyWith(settings: settings));
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }
}
