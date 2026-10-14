import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class WatchLists implements StreamUseCase<List<ListSummary>, NoParams> {
  const WatchLists(this._repository);

  final ShoppingListRepository _repository;

  @override
  Stream<Either<Failure, List<ListSummary>>> call(NoParams params) {
    return _repository.watchLists();
  }
}
