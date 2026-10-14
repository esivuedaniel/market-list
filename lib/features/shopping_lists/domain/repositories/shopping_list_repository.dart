import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

abstract class ShoppingListRepository {
  Stream<Either<Failure, List<ListSummary>>> watchLists();
  Future<Either<Failure, ShoppingList>> createList({
    required String name,
    required CurrencyCode currency,
  });
  Future<Either<Failure, Unit>> renameList({
    required String id,
    required String name,
  });
  Future<Either<Failure, Unit>> setCurrency({
    required String id,
    required CurrencyCode currency,
  });
  Future<Either<Failure, Unit>> deleteList(String id);
  Future<Either<Failure, ShoppingList>> duplicateList(String id);
  Future<Either<Failure, int>> listCount();
}
