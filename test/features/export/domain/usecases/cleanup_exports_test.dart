import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/export/domain/services/export_file_store.dart';
import 'package:market_list/features/export/domain/usecases/cleanup_exports.dart';

class MockExportFileStore extends Mock implements ExportFileStore {}

void main() {
  late MockExportFileStore fileStore;
  late CleanupExports useCase;

  setUpAll(() {
    registerFallbackValue(const Duration(hours: 1));
  });

  setUp(() {
    fileStore = MockExportFileStore();
    useCase = CleanupExports(fileStore);
  });

  group('CleanupExports', () {
    test('FR-070 calls fileStore.deleteOlderThan with 24 hours', () async {
      when(() => fileStore.deleteOlderThan(const Duration(hours: 24)))
          .thenAnswer((_) async => const Right(unit));

      final result = await useCase(const NoParams());

      expect(result, const Right(unit));
      verify(() => fileStore.deleteOlderThan(const Duration(hours: 24))).called(1);
    });

    test('FR-070 returns Failure when fileStore fails', () async {
      when(() => fileStore.deleteOlderThan(any()))
          .thenAnswer((_) async => const Left(UnexpectedFailure('FS error')));

      final result = await useCase(const NoParams());

      expect(result, const Left(UnexpectedFailure('FS error')));
    });
  });
}
