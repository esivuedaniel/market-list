import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

class AppSettings extends Equatable {
  const AppSettings({
    required this.defaultCurrency,
    required this.themeMode,
    required this.onboardingDone,
  });

  final CurrencyCode defaultCurrency;
  final AppThemeMode themeMode;
  final bool onboardingDone;

  AppSettings copyWith({
    CurrencyCode? defaultCurrency,
    AppThemeMode? themeMode,
    bool? onboardingDone,
  }) {
    return AppSettings(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      themeMode: themeMode ?? this.themeMode,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  @override
  List<Object?> get props => [defaultCurrency, themeMode, onboardingDone];
}
