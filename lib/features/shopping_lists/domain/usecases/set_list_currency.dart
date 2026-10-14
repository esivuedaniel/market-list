import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class SetListCurrencyParams extends Equatable {
  const SetListCurrencyParams({
    required this.listId,
    required this.currency,
  });

  final String listId;
  final CurrencyCode currency;

  @override
  List<Object?> get props => [listId, currency];
}

class SetListCurrency implements UseCase<Unit, SetListCurrencyParams> {
  const SetListCurrency(this._repository);

  final ShoppingListRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetListCurrencyParams params) {
    return _repository.setCurrency(
      id: params.listId,
      currency: params.currency,
    );
  }
}
