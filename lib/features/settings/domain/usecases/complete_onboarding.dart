import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/repositories/onboarding_repository.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class CompleteOnboarding implements UseCase<ShoppingList, CurrencyCode> {
  const CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  @override
  Future<Either<Failure, ShoppingList>> call(CurrencyCode currency) {
    return _repository.complete(currency);
  }
}
