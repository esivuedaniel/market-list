import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> ensureSettings(String? regionCode);

  Stream<Either<Failure, AppSettings>> watchSettings();

  Future<Either<Failure, Unit>> setDefaultCurrency(CurrencyCode code);

  Future<Either<Failure, Unit>> setThemeMode(AppThemeMode mode);
}
