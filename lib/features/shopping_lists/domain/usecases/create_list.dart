import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class CreateListParams extends Equatable {
  const CreateListParams({
    required this.name,
    required this.currency,
  });

  final String name;
  final CurrencyCode currency;

  @override
  List<Object?> get props => [name, currency];
}

class CreateList implements UseCase<ShoppingList, CreateListParams> {
  const CreateList(this._repository);

  final ShoppingListRepository _repository;

  @override
  Future<Either<Failure, ShoppingList>> call(CreateListParams params) async {
    final normalized = TextNormalizer.normalize(params.name);

    if (normalized.isEmpty) {
      return const Left(ValidationFailure('Enter a list name.'));
    }

    if (TextNormalizer.codePointLength(normalized) > AppLimits.maxListNameLength) {
      return const Left(
          ValidationFailure('List name must be 60 characters or fewer.'));
    }

    final countResult = await _repository.listCount();
    return countResult.fold(
      Left.new,
      (count) async {
        if (count >= AppLimits.maxLists) {
          return const Left(LimitFailure(LimitKind.lists));
        }
        return _repository.createList(
          name: normalized,
          currency: params.currency,
        );
      },
    );
  }
}
