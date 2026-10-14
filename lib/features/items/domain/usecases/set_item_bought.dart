import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class SetItemBoughtParams extends Equatable {
  const SetItemBoughtParams({
    required this.itemId,
    required this.isBought,
  });

  final String itemId;
  final bool isBought;

  @override
  List<Object?> get props => [itemId, isBought];
}

class SetItemBought implements UseCase<Unit, SetItemBoughtParams> {
  const SetItemBought(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetItemBoughtParams params) {
    return _repository.setBought(
      id: params.itemId,
      isBought: params.isBought,
    );
  }
}
