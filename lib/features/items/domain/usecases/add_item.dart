import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class AddItemParams extends Equatable {
  const AddItemParams({
    required this.listId,
    required this.draft,
  });

  final String listId;
  final ItemDraft draft;

  @override
  List<Object?> get props => [listId, draft];
}

class AddItem implements UseCase<ShoppingItem, AddItemParams> {
  const AddItem(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, ShoppingItem>> call(AddItemParams params) async {
    final countResult = await _repository.itemCount(params.listId);
    return countResult.fold(
      Left.new,
      (count) async {
        if (count >= AppLimits.maxItemsPerList) {
          return const Left(LimitFailure(LimitKind.items));
        }
        return _repository.addItem(
          listId: params.listId,
          draft: params.draft,
        );
      },
    );
  }
}
