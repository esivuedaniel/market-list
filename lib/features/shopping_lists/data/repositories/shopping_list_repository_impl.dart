import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/shopping_lists/data/datasources/shopping_list_local_data_source.dart';
import 'package:market_list/features/shopping_lists/data/mappers/shopping_list_mapper.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/domain/repositories/shopping_list_repository.dart';

class ShoppingListRepositoryImpl implements ShoppingListRepository {
  final ShoppingListLocalDataSource _dataSource;
  final ShoppingListMapper _mapper;
  final IdGenerator _idGenerator;
  final Clock _clock;

  ShoppingListRepositoryImpl({
    required ShoppingListLocalDataSource dataSource,
    required ShoppingListMapper mapper,
    required IdGenerator idGenerator,
    required Clock clock,
  })  : _dataSource = dataSource,
        _mapper = mapper,
        _idGenerator = idGenerator,
        _clock = clock;

  @override
  Stream<Either<Failure, List<ListSummary>>> watchLists() {
    try {
      return _dataSource.watchSummaries().transform(
            StreamTransformer.fromHandlers(
              handleData: (rows, sink) {
                sink.add(Right(rows.map(_mapper.toSummaryEntity).toList()));
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
  Future<Either<Failure, ShoppingList>> createList({
    required String name,
    required CurrencyCode currency,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final id = _idGenerator.generate();

      final companion = _mapper.toCompanion(
        id: id,
        name: name,
        currency: currency,
        createdAt: now,
        updatedAt: now,
      );

      await _dataSource.insertList(companion);

      return Right(ShoppingList(
        id: id,
        name: name,
        currency: currency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      ));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> renameList({
    required String id,
    required String name,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final rows = await _dataSource.renameList(id, name, now);
      if (rows == 0) {
        return const Left(NotFoundFailure());
      }
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setCurrency({
    required String id,
    required CurrencyCode currency,
  }) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final rows = await _dataSource.setCurrency(id, currency.code, now);
      if (rows == 0) {
        return const Left(NotFoundFailure());
      }
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteList(String id) async {
    try {
      final existing = await _dataSource.getList(id);
      if (existing == null) {
        return const Left(NotFoundFailure());
      }
      await _dataSource.deleteList(id);
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, ShoppingList>> duplicateList(String id) async {
    try {
      final count = await _dataSource.listCount();
      if (count >= AppLimits.maxLists) {
        return const Left(LimitFailure(LimitKind.lists));
      }

      final source = await _dataSource.getList(id);
      if (source == null) {
        return const Left(NotFoundFailure());
      }

      final now = _clock.now().millisecondsSinceEpoch;
      final newId = _idGenerator.generate();
      final newItemIds = List.generate(
        AppLimits.maxItemsPerList,
        (_) => _idGenerator.generate(),
      );

      final duplicatedRow = await _dataSource.duplicateList(
        sourceId: id,
        newId: newId,
        newName: source.name,
        nowEpochMs: now,
        newItemIds: newItemIds,
      );

      return Right(_mapper.toEntity(duplicatedRow));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, int>> listCount() async {
    try {
      final count = await _dataSource.listCount();
      return Right(count);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }
}
