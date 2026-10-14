import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class GetListDetail implements UseCase<ListDetail, String> {
  const GetListDetail(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, ListDetail>> call(String listId) {
    return _repository.getListDetail(listId);
  }
}
