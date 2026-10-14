import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/features/export/data/services/temp_export_file_store.dart';

class FakeClock extends Clock {
  const FakeClock(this._now);
  final DateTime _now;

  @override
  DateTime now() => _now;
}

void main() {
  late Directory tempDir;
  late FakeClock fakeClock;
  late TempExportFileStore fileStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('export_store_test_');
    fakeClock = FakeClock(DateTime.utc(2026, 10, 14, 12));
    fileStore = TempExportFileStore(
      getTempDir: () async => tempDir,
      clock: fakeClock,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TempExportFileStore', () {
    test('FR-070 generates slug and file name according to section 11.3', () {
      final date = DateTime.utc(2026, 10, 12);

      // Normal slug
      expect(
        TempExportFileStore.generateExportFileName('Sunday market', date),
        'Sunday-market-20261012.pdf',
      );

      // Special characters and runs of spaces
      expect(
        TempExportFileStore.generateExportFileName('  Tomatoes & Onions!!!  ', date),
        'Tomatoes-Onions-20261012.pdf',
      );

      // Empty or non-alphanumeric becomes shopping-list
      expect(
        TempExportFileStore.generateExportFileName('---***---', date),
        'shopping-list-20261012.pdf',
      );
      expect(
        TempExportFileStore.generateExportFileName('   ', date),
        'shopping-list-20261012.pdf',
      );

      // Long name cut to 40 characters
      final longName = 'A' * 60;
      final fileName = TempExportFileStore.generateExportFileName(longName, date);
      expect(fileName, '${'A' * 40}-20261012.pdf');
    });

    test('FR-070 creates export directory and file path correctly', () async {
      final file = await fileStore.getExportFile('test.pdf');
      expect(file.path.endsWith('exports/test.pdf'), isTrue);
      expect(await file.parent.exists(), isTrue);
    });

    test('FR-070 deleteOlderThan deletes files older than duration and keeps newer', () async {
      final exportDir = await fileStore.getExportDirectory();

      final oldFile = File('${exportDir.path}/old.pdf');
      await oldFile.writeAsString('old');
      // Set modification time 25 hours ago
      await oldFile.setLastModified(fakeClock.now().subtract(const Duration(hours: 25)));

      final newFile = File('${exportDir.path}/new.pdf');
      await newFile.writeAsString('new');
      // Set modification time 1 hour ago
      await newFile.setLastModified(fakeClock.now().subtract(const Duration(hours: 1)));

      final result = await fileStore.deleteOlderThan(const Duration(hours: 24));

      expect(result, const Right(unit));
      expect(await oldFile.exists(), isFalse);
      expect(await newFile.exists(), isTrue);
    });

    test('FR-070 deleteOlderThan returns Right(unit) when export directory does not exist', () async {
      final nonExistentStore = TempExportFileStore(
        getTempDir: () async => Directory('/non/existent/path/for/test'),
        clock: fakeClock,
      );

      final result = await nonExistentStore.deleteOlderThan(const Duration(hours: 24));
      expect(result, const Right(unit));
    });

    test('FR-070 deleteOlderThan returns Left(ExportFailure) on exception', () async {
      final errorStore = TempExportFileStore(
        getTempDir: () async => throw const FileSystemException('Permission denied'),
        clock: fakeClock,
      );

      final result = await errorStore.deleteOlderThan(const Duration(hours: 24));
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ExportFailure>()),
        (_) => fail('should fail'),
      );
    });
  });
}
