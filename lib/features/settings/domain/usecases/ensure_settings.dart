import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';

class EnsureSettingsResult extends Equatable {
  const EnsureSettingsResult({
    required this.settings,
    required this.suggestedCurrency,
  });

  final AppSettings settings;
  final CurrencyCode suggestedCurrency;

  @override
  List<Object?> get props => [settings, suggestedCurrency];
}

class EnsureSettings implements UseCase<EnsureSettingsResult, String?> {
  const EnsureSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, EnsureSettingsResult>> call(String? regionCode) async {
    final result = await _repository.ensureSettings(regionCode);
    return result.map(
      (settings) => EnsureSettingsResult(
        settings: settings,
        suggestedCurrency: CurrencyCode.fromCountryCode(regionCode),
      ),
    );
  }
}
