import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class RenameListParams extends Equatable {
  const RenameListParams({
    required this.listId,
    required this.name,
  });

  final String listId;
  final String name;

  @override
  List<Object?> get props => [listId, name];
}

class RenameList implements UseCase<Unit, RenameListParams> {
  const RenameList(this._repository);

  final ShoppingListRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(RenameListParams params) async {
    final normalized = TextNormalizer.normalize(params.name);

    if (normalized.isEmpty) {
      return const Left(ValidationFailure('Enter a list name.'));
    }

    if (TextNormalizer.codePointLength(normalized) > AppLimits.maxListNameLength) {
      return const Left(
          ValidationFailure('List name must be 60 characters or fewer.'));
    }

    return _repository.renameList(
      id: params.listId,
      name: normalized,
    );
  }
}
