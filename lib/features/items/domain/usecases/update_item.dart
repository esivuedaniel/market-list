import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class UpdateItemParams extends Equatable {
  const UpdateItemParams({
    required this.itemId,
    required this.draft,
  });

  final String itemId;
  final ItemDraft draft;

  @override
  List<Object?> get props => [itemId, draft];
}

class UpdateItem implements UseCase<ShoppingItem, UpdateItemParams> {
  const UpdateItem(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, ShoppingItem>> call(UpdateItemParams params) {
    return _repository.updateItem(
      id: params.itemId,
      draft: params.draft,
    );
  }
}
