import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/domain/entities/app_theme_mode.dart';
import 'package:market_list/features/settings/domain/repositories/settings_repository.dart';
import 'package:market_list/features/settings/domain/usecases/set_theme_mode.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late SetThemeMode useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = SetThemeMode(repository);
  });

  group('SetThemeMode', () {
    test('FR-091 sets theme mode successfully', () async {
      when(() => repository.setThemeMode(AppThemeMode.dark))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase(AppThemeMode.dark);

      expect(result, const Right(unit));
      verify(() => repository.setThemeMode(AppThemeMode.dark)).called(1);
    });

    test('FR-091 returns Failure when repository fails', () async {
      when(() => repository.setThemeMode(AppThemeMode.dark))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(AppThemeMode.dark);

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
