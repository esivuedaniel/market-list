import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class DuplicateCheckParams extends Equatable {
  const DuplicateCheckParams({
    required this.listId,
    required this.name,
    this.excludeItemId,
  });

  final String listId;
  final String name;
  final String? excludeItemId;

  @override
  List<Object?> get props => [listId, name, excludeItemId];
}

class HasDuplicateItemName implements UseCase<bool, DuplicateCheckParams> {
  const HasDuplicateItemName(this._repository);

  final ShoppingItemRepository _repository;

  @override
  Future<Either<Failure, bool>> call(DuplicateCheckParams params) {
    final normalized = TextNormalizer.normalize(params.name);
    if (normalized.isEmpty) {
      return Future.value(const Right(false));
    }
    return _repository.hasDuplicateName(
      listId: params.listId,
      name: normalized,
      excludeId: params.excludeItemId,
    );
  }
}
