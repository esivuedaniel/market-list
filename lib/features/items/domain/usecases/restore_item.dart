import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class RestoreItem implements UseCase<Unit, ShoppingItem> {
  const RestoreItem(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ShoppingItem item) async {
    final countResult = await _repository.itemCount(item.listId);
    return countResult.fold(
      Left.new,
      (count) async {
        if (count >= AppLimits.maxItemsPerList) {
          return const Left(LimitFailure(LimitKind.items));
        }
        return _repository.restoreItem(item);
      },
    );
  }
}
