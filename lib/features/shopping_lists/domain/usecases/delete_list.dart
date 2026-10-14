import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class DeleteList implements UseCase<Unit, String> {
  const DeleteList(this._repository);

  final ShoppingListRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String listId) {
    return _repository.deleteList(listId);
  }
}
