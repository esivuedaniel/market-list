import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/core/platform/id_generator.dart';
import 'package:market_list/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:market_list/features/settings/data/repositories/onboarding_repository_impl.dart';

class MockSettingsLocalDataSource extends Mock
    implements SettingsLocalDataSource {}

class MockIdGenerator extends Mock implements IdGenerator {}

class MockClock extends Mock implements Clock {}

void main() {
  late MockSettingsLocalDataSource mockDataSource;
  late MockIdGenerator mockIdGenerator;
  late MockClock mockClock;
  late OnboardingRepositoryImpl repository;

  final testNow = DateTime.utc(2026, 10, 14, 12, 0);

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();
    mockIdGenerator = MockIdGenerator();
    mockClock = MockClock();

    when(() => mockClock.now()).thenReturn(testNow);
    when(() => mockIdGenerator.generate()).thenReturn('onboarding-list-id');

    repository = OnboardingRepositoryImpl(
      dataSource: mockDataSource,
      idGenerator: mockIdGenerator,
      clock: mockClock,
    );
  });

  group('OnboardingRepositoryImpl', () {
    test('FR-092 complete finishes onboarding and returns created ShoppingList', () async {
      when(
        () => mockDataSource.completeOnboarding(
          currencyCode: 'USD',
          listId: 'onboarding-list-id',
          listName: 'Market list',
          nowEpochMs: testNow.millisecondsSinceEpoch,
        ),
      ).thenAnswer(
        (_) async => ShoppingListRow(
          id: 'onboarding-list-id',
          name: 'Market list',
          currencyCode: 'USD',
          createdAt: testNow.millisecondsSinceEpoch,
          updatedAt: testNow.millisecondsSinceEpoch,
        ),
      );

      final result = await repository.complete(CurrencyCode.usd);
      expect(result.isRight(), isTrue);
      result.match(
        (l) => fail('Expected Right'),
        (r) {
          expect(r.id, 'onboarding-list-id');
          expect(r.name, 'Market list');
          expect(r.currency, CurrencyCode.usd);
        },
      );
    });

    test('FR-092 complete returns Left when data source throws', () async {
      when(
        () => mockDataSource.completeOnboarding(
          currencyCode: any(named: 'currencyCode'),
          listId: any(named: 'listId'),
          listName: any(named: 'listName'),
          nowEpochMs: any(named: 'nowEpochMs'),
        ),
      ).thenThrow(SqliteException(13, 'disk full'));

      final result = await repository.complete(CurrencyCode.usd);
      expect(result, const Left(StorageFullFailure()));
    });
  });
}
