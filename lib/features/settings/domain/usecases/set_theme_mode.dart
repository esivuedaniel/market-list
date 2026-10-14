import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';

class SetThemeMode implements UseCase<Unit, AppThemeMode> {
  const SetThemeMode(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AppThemeMode themeMode) {
    return _repository.setThemeMode(themeMode);
  }
}
