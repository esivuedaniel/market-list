import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';

abstract class ShareService {
  Future<Either<Failure, ShareOutcome>> shareFile({
    required String path,
    required String subject,
    String? text,
  });

  Future<Either<Failure, ShareOutcome>> shareText(String text);
}
