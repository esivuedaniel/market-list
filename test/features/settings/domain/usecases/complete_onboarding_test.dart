import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/settings/domain/repositories/onboarding_repository.dart';
import 'package:market_list/features/settings/domain/usecases/complete_onboarding.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository repository;
  late CompleteOnboarding useCase;

  setUp(() {
    repository = MockOnboardingRepository();
    useCase = CompleteOnboarding(repository);
  });

  final now = DateTime.utc(2026, 10, 14);
  final firstList = ShoppingList(
    id: 'first-list-1',
    name: 'Market list',
    currency: CurrencyCode.ngn,
    createdAt: now,
    updatedAt: now,
  );

  group('CompleteOnboarding', () {
    test('FR-092 completes onboarding and returns first ShoppingList', () async {
      when(() => repository.complete(CurrencyCode.ngn))
          .thenAnswer((_) async => Right(firstList));

      final result = await useCase(CurrencyCode.ngn);

      expect(result, Right(firstList));
      verify(() => repository.complete(CurrencyCode.ngn)).called(1);
    });

    test('FR-092 returns Failure when repository complete fails', () async {
      when(() => repository.complete(CurrencyCode.ngn))
          .thenAnswer((_) async => const Left(DatabaseFailure('DB error')));

      final result = await useCase(CurrencyCode.ngn);

      expect(result, const Left(DatabaseFailure('DB error')));
    });
  });
}
