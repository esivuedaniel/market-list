import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:market_list/features/settings/data/mappers/settings_mapper.dart';
import 'package:market_list/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';

class MockSettingsLocalDataSource extends Mock
    implements SettingsLocalDataSource {}

void main() {
  late MockSettingsLocalDataSource mockDataSource;
  late SettingsMapper mapper;
  late SettingsRepositoryImpl repository;

  const testSettingsRow = AppSettingsRow(
    id: 1,
    defaultCurrencyCode: 'USD',
    themeMode: 'system',
    onboardingDone: false,
  );

  setUpAll(() {
    registerFallbackValue(
      const AppSettingsTableCompanion(),
    );
  });

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();
    mapper = const SettingsMapper();
    repository = SettingsRepositoryImpl(
      dataSource: mockDataSource,
      mapper: mapper,
    );
  });

  group('SettingsRepositoryImpl', () {
    test('FR-080 ensureSettings returns existing settings if present', () async {
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => testSettingsRow);

      final result = await repository.ensureSettings('US');
      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.defaultCurrency, CurrencyCode.usd);
          expect(r.themeMode, AppThemeMode.system);
        },
      );
    });

    test('FR-080 ensureSettings creates initial settings when none exists', () async {
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => null);
      when(() => mockDataSource.insertSettings(any())).thenAnswer((_) async {});

      final result = await repository.ensureSettings('NG');
      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.defaultCurrency, CurrencyCode.ngn);
          expect(r.themeMode, AppThemeMode.system);
          expect(r.onboardingDone, isFalse);
        },
      );
    });

    test('FR-080 ensureSettings returns Left when data source throws', () async {
      when(() => mockDataSource.getSettings()).thenThrow(SqliteException(13, 'disk full'));

      final result = await repository.ensureSettings('US');
      expect(result, const Left(StorageFullFailure()));
    });

    test('FR-080 watchSettings emits mapped settings and handles NotFound/error', () async {
      // 1. Success
      when(() => mockDataSource.watchSettings()).thenAnswer(
        (_) => Stream.value(testSettingsRow),
      );
      final successRes = await repository.watchSettings().first;
      expect(successRes.isRight(), isTrue);

      // 2. Not found
      when(() => mockDataSource.watchSettings()).thenAnswer(
        (_) => Stream.value(null),
      );
      final notFoundRes = await repository.watchSettings().first;
      expect(notFoundRes, const Left(NotFoundFailure()));

      // 3. Error
      when(() => mockDataSource.watchSettings()).thenAnswer(
        (_) => Stream.error(SqliteException(13, 'disk full')),
      );
      final errRes = await repository.watchSettings().first;
      expect(errRes, const Left(StorageFullFailure()));
    });

    test('FR-080 setDefaultCurrency updates and returns Right(unit)', () async {
      when(() => mockDataSource.updateDefaultCurrency('EUR')).thenAnswer((_) async {});

      final result = await repository.setDefaultCurrency(CurrencyCode.eur);
      expect(result, const Right(unit));
    });

    test('FR-080 setDefaultCurrency returns Left when data source throws', () async {
      when(() => mockDataSource.updateDefaultCurrency('EUR'))
          .thenThrow(SqliteException(1, 'db err'));

      final result = await repository.setDefaultCurrency(CurrencyCode.eur);
      expect(result, const Left(DatabaseFailure('db err')));
    });

    test('FR-080 setThemeMode updates and returns Right(unit)', () async {
      when(() => mockDataSource.updateThemeMode('dark')).thenAnswer((_) async {});

      final result = await repository.setThemeMode(AppThemeMode.dark);
      expect(result, const Right(unit));
    });

    test('FR-080 setThemeMode returns Left when data source throws', () async {
      when(() => mockDataSource.updateThemeMode('dark'))
          .thenThrow(SqliteException(1, 'db err'));

      final result = await repository.setThemeMode(AppThemeMode.dark);
      expect(result, const Left(DatabaseFailure('db err')));
    });
  });
}
