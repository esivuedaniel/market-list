import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';
import 'package:market_list/features/export/domain/usecases/share_file.dart';

class MockShareService extends Mock implements ShareService {}

void main() {
  late MockShareService shareService;
  late ShareFile useCase;

  setUp(() {
    shareService = MockShareService();
    useCase = ShareFile(shareService);
  });

  group('ShareFile', () {
    test('FR-070 calls shareService.shareFile with params and returns ShareOutcome', () async {
      when(() => shareService.shareFile(
            path: '/path/file.pdf',
            subject: 'Sunday market',
            text: 'Shopping list: Sunday market',
          )).thenAnswer((_) async => const Right(ShareOutcome.success));

      final result = await useCase(const ShareFileParams(
        path: '/path/file.pdf',
        subject: 'Sunday market',
        text: 'Shopping list: Sunday market',
      ));

      expect(result, const Right(ShareOutcome.success));
      verify(() => shareService.shareFile(
            path: '/path/file.pdf',
            subject: 'Sunday market',
            text: 'Shopping list: Sunday market',
          )).called(1);
    });

    test('FR-070 returns ShareFailure when shareService fails', () async {
      when(() => shareService.shareFile(
            path: any(named: 'path'),
            subject: any(named: 'subject'),
            text: any(named: 'text'),
          )).thenAnswer((_) async => const Left(ShareFailure('Cannot share file')));

      final result = await useCase(const ShareFileParams(
        path: '/path/file.pdf',
        subject: 'Sunday market',
      ));

      expect(result, const Left(ShareFailure('Cannot share file')));
      expect(const ShareFileParams(path: '/path/file.pdf', subject: 'Sunday market').props, ['/path/file.pdf', 'Sunday market', null]);
    });
  });
}
