import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:market_list/features/settings/domain/usecases/set_default_currency.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late SetDefaultCurrency useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SetDefaultCurrency(repository);
  });

  group('SetDefaultCurrency', () {
    test('FR-090 sets default currency successfully', () async {
      when(() => repository.setDefaultCurrency(CurrencyCode.ngn))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase(CurrencyCode.ngn);

      expect(result, const Right(unit));
      verify(() => repository.setDefaultCurrency(CurrencyCode.ngn)).called(1);
    });

    test('FR-090 returns Failure when repository fails', () async {
      when(() => repository.setDefaultCurrency(CurrencyCode.ngn))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(CurrencyCode.ngn);

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
