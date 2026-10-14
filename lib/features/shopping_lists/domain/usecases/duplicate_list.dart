import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class DuplicateList implements UseCase<ShoppingList, String> {
  const DuplicateList(this._repository);

  final ShoppingListRepository _repository;

  @override
  Future<Either<Failure, ShoppingList>> call(String listId) async {
    final countResult = await _repository.listCount();
    return countResult.fold(
      Left.new,
      (count) async {
        if (count >= AppLimits.maxLists) {
          return const Left(LimitFailure(LimitKind.lists));
        }
        return _repository.duplicateList(listId);
      },
    );
  }
}
