import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';

class WatchSettings implements StreamUseCase<AppSettings, NoParams> {
  const WatchSettings(this._repository);

  final SettingsRepository _repository;

  @override
  Stream<Either<Failure, AppSettings>> call(NoParams params) {
    return _repository.watchSettings();
  }
}
