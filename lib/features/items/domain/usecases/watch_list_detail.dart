import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class WatchListDetail implements StreamUseCase<ListDetail, String> {
  const WatchListDetail(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Stream<Either<Failure, ListDetail>> call(String listId) {
    return _repository.watchListDetail(listId);
  }
}
