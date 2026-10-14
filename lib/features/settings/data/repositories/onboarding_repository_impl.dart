import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:market_list/features/settings/domain/repositories/onboarding_repository.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final SettingsLocalDataSource _dataSource;
  final IdGenerator _idGenerator;
  final Clock _clock;

  OnboardingRepositoryImpl({
    required SettingsLocalDataSource dataSource,
    required IdGenerator idGenerator,
    required Clock clock,
  })  : _dataSource = dataSource,
        _idGenerator = idGenerator,
        _clock = clock;

  @override
  Future<Either<Failure, ShoppingList>> complete(CurrencyCode currency) async {
    try {
      final now = _clock.now().millisecondsSinceEpoch;
      final listId = _idGenerator.generate();

      final listRow = await _dataSource.completeOnboarding(
        currencyCode: currency.code,
        listId: listId,
        listName: 'Market list',
        nowEpochMs: now,
      );

      return Right(ShoppingList(
        id: listRow.id,
        name: listRow.name,
        currency: CurrencyCode.fromCode(listRow.currencyCode),
        createdAt: DateTime.fromMillisecondsSinceEpoch(listRow.createdAt, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(listRow.updatedAt, isUtc: true),
      ));
    } catch (e) {
      return Left(mapDatabaseException(e));
    }
  }
}
