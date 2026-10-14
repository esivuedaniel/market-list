import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class GetItem implements UseCase<ShoppingItem, String> {
  const GetItem(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, ShoppingItem>> call(String id) {
    return _repository.getItem(id);
  }
}
