import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';

class ShareFileParams extends Equatable {
  const ShareFileParams({
    required this.path,
    required this.subject,
    this.text,
  });

  final String path;
  final String subject;
  final String? text;

  @override
  List<Object?> get props => [path, subject, text];
}

class ShareFile implements UseCase<ShareOutcome, ShareFileParams> {
  const ShareFile(this._shareService);

  final ShareService _shareService;

  @override
  Future<Either<Failure, ShareOutcome>> call(ShareFileParams params) {
    return _shareService.shareFile(
      path: params.path,
      subject: params.subject,
      text: params.text,
    );
  }
}
