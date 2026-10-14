import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

abstract class ShoppingItemRepository {
  Stream<Either<Failure, ListDetail>> watchListDetail(String listId);
  Future<Either<Failure, ListDetail>> getListDetail(String listId);
  Future<Either<Failure, ShoppingItem>> getItem(String id);
  Future<Either<Failure, ShoppingItem>> addItem({
    required String listId,
    required ItemDraft draft,
  });
  Future<Either<Failure, ShoppingItem>> updateItem({
    required String id,
    required ItemDraft draft,
  });
  Future<Either<Failure, ShoppingItem>> deleteItem(String id);
  Future<Either<Failure, Unit>> restoreItem(ShoppingItem item);
  Future<Either<Failure, Unit>> setBought({
    required String id,
    required bool isBought,
  });
  Future<Either<Failure, int>> itemCount(String listId);
  Future<Either<Failure, bool>> hasDuplicateName({
    required String listId,
    required String name,
    String? excludeId,
  });
}
