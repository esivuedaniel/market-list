import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/items/data/datasources/shopping_item_local_data_source.dart';
import 'package:market_list/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/repositories/shopping_item_repository.dart';

class ShoppingItemRepositoryImpl implements ShoppingItemRepository {
  final ShoppingItemLocalDataSource _dataSource;
  final ShoppingItemMapper _mapper;
  final IdGenerator _idGenerator;
  final Clock _clock;

  ShoppingItemRepositoryImpl({
    required ShoppingItemLocalDataSource dataSource,
    required ShoppingItemMapper mapper,
    required IdGenerator idGenerator,
    required Clock clock,
  })  : _dataSource = dataSource,
        _mapper = mapper,
        _idGenerator = idGenerator,
        _clock = clock;

  @override
  Stream<Either<Failure, ListDetail>> watchListDetail(String listId) {
    try {
      return _dataSource.watchListWithItems(listId).transform(
            StreamTransformer.fromHandlers(
              handleData: (row, sink) {
                if (row == null) {
                  sink.add(const Left(NotFoundFailure()));
                } else {
                  sink.add(Right(_mapper.toListDetailEntity(row)));
                }
              },
              handleError: (error, stackTrace, sink) {
                sink.add(Left(mapDatabaseException(error)));
              },
            ),
          );
    } catch (e) {
      return Stream.value(Left(mapDatabaseException(e)));
    }
  }

  @override
  Future<Either<Failure, ListDetail>> getListDetail(String listId) async {
    try {
      final row = await _dataSource.getListDetail(listId);
      if (row == null) {
        return const Left(NotFoundFailure());
      }
      return Right(_mapper.toListDetailEntity(row));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, ShoppingItem>> getItem(String id) async {
    try {
      final row = await _dataSource.getItem(id);
      if (row == null) {
        return const Left(NotFoundFailure());
      }
      return Right(_mapper.toEntity(row));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, ShoppingItem>> addItem({
    required String listId,
    required ItemDraft draft,
  }) async {
    try {
      final id = _idGenerator.generate();
      final now = _clock.now().millisecondsSinceEpoch;

      final companion = _mapper.toInsertCompanion(
        id: id,
        listId: listId,
        draft: draft,
        createdAt: now,
        updatedAt: now,
      );

      final row = await _dataSource.insertItem(companion, now);
      return Right(_mapper.toEntity(row));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, ShoppingItem>> updateItem({
    required String id,
    required ItemDraft draft,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final companion = _mapper.toUpdateCompanion(
        id: id,
        draft: draft,
        updatedAt: now,
      );

      final row = await _dataSource.updateItem(companion, now);
      if (row == null) {
        return const Left(NotFoundFailure());
      }
      return Right(_mapper.toEntity(row));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, ShoppingItem>> deleteItem(String id) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final deletedRow = await _dataSource.deleteItem(id, now);
      if (deletedRow == null) {
        return const Left(NotFoundFailure());
      }
      return Right(_mapper.toEntity(deletedRow));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreItem(ShoppingItem item) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final row = ShoppingItemRow(
        id: item.id,
        listId: item.listId,
        name: item.name,
        quantityMilli: item.quantity.milli,
        unit: item.unit,
        unitPriceMinor: item.unitPrice.minor,
        isBought: item.isBought,
        createdAt: item.createdAt.millisecondsSinceEpoch,
        updatedAt: now,
      );

      await _dataSource.restoreItem(row, now);
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setBought({
    required String id,
    required bool isBought,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final rows = await _dataSource.setBought(id, isBought, now);
      if (rows == 0) {
        return const Left(NotFoundFailure());
      }
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, int>> itemCount(String listId) async {
    try {
      final count = await _dataSource.itemCount(listId);
      return Right(count);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> hasDuplicateName({
    required String listId,
    required String name,
    String? excludeId,
  }) async {
    try {
      final exists = await _dataSource.hasDuplicateName(
        listId,
        name,
        excludeId,
      );
      return Right(exists);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }
}
