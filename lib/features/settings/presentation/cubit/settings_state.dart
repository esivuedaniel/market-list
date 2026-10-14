import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';

enum SettingsStatus {
  loading,
  needsOnboarding,
  loaded,
  failure,
}

class SettingsState extends Equatable {
  const SettingsState({
    required this.status,
    this.settings,
    this.suggestedCurrency,
    this.firstListId,
    this.message,
  });

  const SettingsState.initial()
      : status = SettingsStatus.loading,
        settings = null,
        suggestedCurrency = null,
        firstListId = null,
        message = null;

  final SettingsStatus status;
  final AppSettings? settings;
  final CurrencyCode? suggestedCurrency;
  final String? firstListId;
  final String? message;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    CurrencyCode? suggestedCurrency,
    String? firstListId,
    String? message,
    bool clearFirstListId = false,
    bool clearMessage = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      suggestedCurrency: suggestedCurrency ?? this.suggestedCurrency,
      firstListId:
          clearFirstListId ? null : (firstListId ?? this.firstListId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        status,
        settings,
        suggestedCurrency,
        firstListId,
        message,
      ];
}
