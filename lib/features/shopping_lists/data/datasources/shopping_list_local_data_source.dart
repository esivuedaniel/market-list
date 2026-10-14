import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/database/daos/lists_dao.dart';

abstract class ShoppingListLocalDataSource {
  Stream<List<ListSummaryRow>> watchSummaries();
  Future<ShoppingListRow?> getList(String id);
  Future<void> insertList(ShoppingListsTableCompanion companion);
  Future<int> renameList(String id, String name, int updatedAt);
  Future<int> setCurrency(String id, String currencyCode, int updatedAt);
  Future<int> deleteList(String id);
  Future<ShoppingListRow> duplicateList({
    required String sourceId,
    required String newId,
    required String newName,
    required int nowEpochMs,
    required List<String> newItemIds,
  });
  Future<int> listCount();
}

class ShoppingListLocalDataSourceImpl implements ShoppingListLocalDataSource {
  final ListsDao _listsDao;

  ShoppingListLocalDataSourceImpl(this._listsDao);

  @override
  Stream<List<ListSummaryRow>> watchSummaries() => _listsDao.watchSummaries();

  @override
  Future<ShoppingListRow?> getList(String id) => _listsDao.getList(id);

  @override
  Future<void> insertList(ShoppingListsTableCompanion companion) =>
      _listsDao.insertList(companion);

  @override
  Future<int> renameList(String id, String name, int updatedAt) =>
      _listsDao.renameList(id, name, updatedAt);

  @override
  Future<int> setCurrency(String id, String currencyCode, int updatedAt) =>
      _listsDao.setCurrency(id, currencyCode, updatedAt);

  @override
  Future<int> deleteList(String id) => _listsDao.deleteList(id);

  @override
  Future<ShoppingListRow> duplicateList({
    required String sourceId,
    required String newId,
    required String newName,
    required int nowEpochMs,
    required List<String> newItemIds,
  }) =>
      _listsDao.duplicateList(
        sourceId: sourceId,
        newId: newId,
        newName: newName,
        nowEpochMs: nowEpochMs,
        newItemIds: newItemIds,
      );

  @override
  Future<int> listCount() => _listsDao.listCount();
}
