import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/items_dao.dart';

abstract class ShoppingItemLocalDataSource {
  Stream<ListDetailRow?> watchListWithItems(String listId);
  Future<ListDetailRow?> getListDetail(String listId);
  Future<ShoppingItemRow?> getItem(String id);
  Future<ShoppingItemRow> insertItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  );
  Future<ShoppingItemRow?> updateItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  );
  Future<ShoppingItemRow?> deleteItem(String id, int nowEpochMs);
  Future<void> restoreItem(ShoppingItemRow item, int nowEpochMs);
  Future<int> setBought(String id, bool isBought, int nowEpochMs);
  Future<int> itemCount(String listId);
  Future<bool> hasDuplicateName(
    String listId,
    String normalizedName,
    String? excludeId,
  );
}

class ShoppingItemLocalDataSourceImpl implements ShoppingItemLocalDataSource {
  final ItemsDao _itemsDao;

  ShoppingItemLocalDataSourceImpl(this._itemsDao);

  @override
  Stream<ListDetailRow?> watchListWithItems(String listId) =>
      _itemsDao.watchListWithItems(listId);

  @override
  Future<ListDetailRow?> getListDetail(String listId) =>
      _itemsDao.getListDetail(listId);

  @override
  Future<ShoppingItemRow?> getItem(String id) => _itemsDao.getItem(id);

  @override
  Future<ShoppingItemRow> insertItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  ) =>
      _itemsDao.insertItem(companion, nowEpochMs);

  @override
  Future<ShoppingItemRow?> updateItem(
    ShoppingItemsTableCompanion companion,
    int nowEpochMs,
  ) =>
      _itemsDao.updateItem(companion, nowEpochMs);

  @override
  Future<ShoppingItemRow?> deleteItem(String id, int nowEpochMs) =>
      _itemsDao.deleteItem(id, nowEpochMs);

  @override
  Future<void> restoreItem(ShoppingItemRow item, int nowEpochMs) =>
      _itemsDao.restoreItem(item, nowEpochMs);

  @override
  Future<int> setBought(String id, bool isBought, int nowEpochMs) =>
      _itemsDao.setBought(id, isBought, nowEpochMs);

  @override
  Future<int> itemCount(String listId) => _itemsDao.itemCount(listId);

  @override
  Future<bool> hasDuplicateName(
    String listId,
    String normalizedName,
    String? excludeId,
  ) =>
      _itemsDao.hasDuplicateName(listId, normalizedName, excludeId);
}
