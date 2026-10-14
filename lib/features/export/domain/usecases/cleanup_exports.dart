import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/export/domain/services/export_file_store.dart';

class CleanupExports implements UseCase<Unit, NoParams> {
  const CleanupExports(this._fileStore);

  final ExportFileStore _fileStore;

  static const Duration exportMaxAge = Duration(hours: 24);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _fileStore.deleteOlderThan(exportMaxAge);
  }
}
