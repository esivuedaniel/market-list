import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/settings/domain/entities/app_settings.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:market_list/features/settings/domain/usecases/watch_settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late WatchSettings useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = WatchSettings(repository);
  });

  const settings = AppSettings(
    defaultCurrency: CurrencyCode.usd,
    themeMode: AppThemeMode.system,
    onboardingDone: true,
  );

  group('WatchSettings', () {
    test('FR-090 emits AppSettings from repository stream', () async {
      when(() => repository.watchSettings())
          .thenAnswer((_) => Stream.value(const Right(settings)));

      final stream = useCase(const NoParams());

      expect(stream, emits(const Right<Failure, AppSettings>(settings)));
      verify(() => repository.watchSettings()).called(1);
    });

    test('FR-090 emits Failure when repository stream emits Left', () async {
      when(() => repository.watchSettings())
          .thenAnswer((_) => Stream.value(const Left(DatabaseFailure('DB error'))));

      final stream = useCase(const NoParams());

      expect(
        stream,
        emits(const Left<Failure, AppSettings>(DatabaseFailure('DB error'))),
      );
    });
  });
}
