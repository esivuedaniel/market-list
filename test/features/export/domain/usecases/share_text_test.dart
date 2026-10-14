import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';
import 'package:market_list/features/export/domain/usecases/share_text.dart';

class MockShareService extends Mock implements ShareService {}

void main() {
  late MockShareService shareService;
  late ShareText useCase;

  setUp(() {
    shareService = MockShareService();
    useCase = ShareText(shareService);
  });

  group('ShareText', () {
    test('FR-071 calls shareService.shareText and returns ShareOutcome', () async {
      when(() => shareService.shareText('Exported text content'))
          .thenAnswer((_) async => const Right(ShareOutcome.success));

      final result = await useCase('Exported text content');

      expect(result, const Right(ShareOutcome.success));
      verify(() => shareService.shareText('Exported text content')).called(1);
    });

    test('FR-071 returns ShareFailure when shareService fails', () async {
      when(() => shareService.shareText(any()))
          .thenAnswer((_) async => const Left(ShareFailure('Cannot share text')));

      final result = await useCase('Text');

      expect(result, const Left(ShareFailure('Cannot share text')));
    });
  });
}
