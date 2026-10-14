import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, ShoppingList>> complete(CurrencyCode currency);
}
