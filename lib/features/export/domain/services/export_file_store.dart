import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';

abstract class ExportFileStore {
  Future<Either<Failure, Unit>> deleteOlderThan(Duration duration);
}
