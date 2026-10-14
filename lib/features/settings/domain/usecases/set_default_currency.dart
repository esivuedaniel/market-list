import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';

class SetDefaultCurrency implements UseCase<Unit, CurrencyCode> {
  const SetDefaultCurrency(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(CurrencyCode currency) {
    return _repository.setDefaultCurrency(currency);
  }
}
