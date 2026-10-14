import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/platform/clock.dart';
import 'package:market_list/features/export/domain/services/export_file_store.dart';

class TempExportFileStore implements ExportFileStore {
  TempExportFileStore({
    Future<Directory> Function()? getTempDir,
    Clock clock = const Clock(),
  })  : _getTempDir = getTempDir ?? getTemporaryDirectory,
        _clock = clock;

  final Future<Directory> Function() _getTempDir;
  final Clock _clock;

  static String generateExportFileName(String listName, DateTime date) {
    var slug = listName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.runes.length > 40) {
      slug = String.fromCharCodes(slug.runes.take(40));
    }
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      slug = 'shopping-list';
    }
    final dateStr = DateFormat('yyyyMMdd').format(date);
    return '$slug-$dateStr.pdf';
  }

  Future<Directory> getExportDirectory() async {
    final temp = await _getTempDir();
    final exportDir = Directory(p.join(temp.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  Future<File> getExportFile(String fileName) async {
    final dir = await getExportDirectory();
    return File(p.join(dir.path, fileName));
  }

  @override
  Future<Either<Failure, Unit>> deleteOlderThan(Duration duration) async {
    try {
      final temp = await _getTempDir();
      final exportDir = Directory(p.join(temp.path, 'exports'));
      if (!await exportDir.exists()) {
        return const Right(unit);
      }
      final now = _clock.now();
      await for (final entity in exportDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > duration) {
            await entity.delete();
          }
        }
      }
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ExportFailure(e.toString()));
    }
  }
}
