import 'dart:ui';

import 'package:fpdart/fpdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';

typedef ShareAction = Future<ShareResult> Function(ShareParams params);

class SharePlusService implements ShareService {
  SharePlusService({
    ShareAction? shareAction,
    Rect? defaultOrigin,
  })  : _shareAction = shareAction ?? SharePlus.instance.share,
        _defaultOrigin = defaultOrigin ?? const Rect.fromLTWH(0, 0, 100, 100);

  final ShareAction _shareAction;
  final Rect _defaultOrigin;

  @override
  Future<Either<Failure, ShareOutcome>> shareFile({
    required String path,
    required String subject,
    String? text,
  }) async {
    try {
      final params = ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        subject: subject,
        text: text,
        sharePositionOrigin: _defaultOrigin,
      );
      final result = await _shareAction(params);
      return Right(_mapResult(result.status));
    } on Exception catch (e) {
      return Left(ShareFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShareOutcome>> shareText(String text) async {
    try {
      final params = ShareParams(
        text: text,
        sharePositionOrigin: _defaultOrigin,
      );
      final result = await _shareAction(params);
      return Right(_mapResult(result.status));
    } on Exception catch (e) {
      return Left(ShareFailure(e.toString()));
    }
  }

  ShareOutcome _mapResult(ShareResultStatus status) {
    return switch (status) {
      ShareResultStatus.success => ShareOutcome.success,
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.unavailable => ShareOutcome.unavailable,
    };
  }
}
