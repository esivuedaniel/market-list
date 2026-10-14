import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';

class ShareText implements UseCase<ShareOutcome, String> {
  const ShareText(this._shareService);

  final ShareService _shareService;

  @override
  Future<Either<Failure, ShareOutcome>> call(String text) {
    return _shareService.shareText(text);
  }
}
