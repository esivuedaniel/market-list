import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:market_list/features/settings/domain/usecases/ensure_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late EnsureSettings useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = EnsureSettings(repository);
  });

  const baseSettings = AppSettings(
    defaultCurrency: CurrencyCode.usd,
    themeMode: AppThemeMode.system,
    onboardingDone: false,
  );

  group('EnsureSettings', () {
    test('FR-092 preselects NGN when region is NG', () async {
      when(() => repository.ensureSettings('NG'))
          .thenAnswer((_) async => const Right(baseSettings));

      final result = await useCase('NG');

      expect(
        result,
        const Right(EnsureSettingsResult(
          settings: baseSettings,
          suggestedCurrency: CurrencyCode.ngn,
        )),
      );
      verify(() => repository.ensureSettings('NG')).called(1);
    });

    test('FR-092 preselects USD when region is unsupported or null', () async {
      when(() => repository.ensureSettings('ZZ'))
          .thenAnswer((_) async => const Right(baseSettings));

      final result = await useCase('ZZ');

      expect(
        result,
        const Right(EnsureSettingsResult(
          settings: baseSettings,
          suggestedCurrency: CurrencyCode.usd,
        )),
      );

      when(() => repository.ensureSettings(null))
          .thenAnswer((_) async => const Right(baseSettings));

      final nullResult = await useCase(null);

      expect(
        nullResult,
        const Right(EnsureSettingsResult(
          settings: baseSettings,
          suggestedCurrency: CurrencyCode.usd,
        )),
      );
    });

    test('FR-092 returns Failure when repository ensureSettings fails', () async {
      when(() => repository.ensureSettings(any()))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase('NG');

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
