import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:market_list/features/settings/data/mappers/settings_mapper.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _dataSource;
  final SettingsMapper _mapper;

  SettingsRepositoryImpl({
    required SettingsLocalDataSource dataSource,
    required SettingsMapper mapper,
  })  : _dataSource = dataSource,
        _mapper = mapper;

  @override
  Future<Either<Failure, AppSettings>> ensureSettings([String? regionCode]) async {
    try {
      final existing = await _dataSource.getSettings();
      if (existing != null) {
        return Right(_mapper.toEntity(existing));
      }

      final suggested = CurrencyCode.fromCountryCode(regionCode);
      final initialSettings = AppSettings(
        defaultCurrency: suggested,
        themeMode: AppThemeMode.system,
        onboardingDone: false,
      );

      await _dataSource.insertSettings(_mapper.toCompanion(initialSettings));
      return Right(initialSettings);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Stream<Either<Failure, AppSettings>> watchSettings() {
    try {
      return _dataSource.watchSettings().transform(
            StreamTransformer.fromHandlers(
              handleData: (row, sink) {
                if (row == null) {
                  sink.add(const Left(NotFoundFailure()));
                } else {
                  sink.add(Right(_mapper.toEntity(row)));
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
  Future<Either<Failure, Unit>> setDefaultCurrency(CurrencyCode currency) async {
    try {
      await _dataSource.updateDefaultCurrency(currency.code);
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> setThemeMode(AppThemeMode themeMode) async {
    try {
      await _dataSource.updateThemeMode(themeMode.name);
      return const Right(unit);
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }
}
