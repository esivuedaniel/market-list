import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/data/services/share_plus_service.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';

void main() {
  group('SharePlusService', () {
    test('FR-070 shareFile succeeds with success outcome', () async {
      ShareParams? capturedParams;

      final service = SharePlusService(
        shareAction: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
        defaultOrigin: const Rect.fromLTWH(10, 20, 30, 40),
      );

      final result = await service.shareFile(
        path: '/tmp/test.pdf',
        subject: 'Sunday market',
        text: 'Shopping list: Sunday market',
      );

      expect(result, const Right(ShareOutcome.success));
      expect(capturedParams, isNotNull);
      expect(capturedParams!.files, isNotNull);
      expect(capturedParams!.files!.first.path, '/tmp/test.pdf');
      expect(capturedParams!.files!.first.mimeType, 'application/pdf');
      expect(capturedParams!.subject, 'Sunday market');
      expect(capturedParams!.text, 'Shopping list: Sunday market');
      expect(capturedParams!.sharePositionOrigin, const Rect.fromLTWH(10, 20, 30, 40));
    });

    test('FR-070 shareFile maps dismissed status to ShareOutcome.dismissed', () async {
      final service = SharePlusService(
        shareAction: (params) async =>
            const ShareResult('dismissed', ShareResultStatus.dismissed),
      );

      final result = await service.shareFile(
        path: '/tmp/test.pdf',
        subject: 'Sunday market',
      );

      expect(result, const Right(ShareOutcome.dismissed));
    });

    test('FR-070 shareFile maps unavailable status to ShareOutcome.unavailable', () async {
      final service = SharePlusService(
        shareAction: (params) async =>
            const ShareResult('unavailable', ShareResultStatus.unavailable),
      );

      final result = await service.shareFile(
        path: '/tmp/test.pdf',
        subject: 'Sunday market',
      );

      expect(result, const Right(ShareOutcome.unavailable));
    });

    test('FR-070 shareFile returns ShareFailure when share throws', () async {
      final service = SharePlusService(
        shareAction: (params) async => throw Exception('Platform channel failed'),
      );

      final result = await service.shareFile(
        path: '/tmp/test.pdf',
        subject: 'Sunday market',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ShareFailure>()),
        (_) => fail('should fail'),
      );
    });

    test('FR-071 shareText succeeds with success outcome', () async {
      ShareParams? capturedParams;

      final service = SharePlusService(
        shareAction: (params) async {
          capturedParams = params;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await service.shareText('Shopping list text');

      expect(result, const Right(ShareOutcome.success));
      expect(capturedParams, isNotNull);
      expect(capturedParams!.text, 'Shopping list text');
    });

    test('FR-071 shareText returns ShareFailure when share throws', () async {
      final service = SharePlusService(
        shareAction: (params) async => throw Exception('Share sheet crashed'),
      );

      final result = await service.shareText('Shopping list text');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ShareFailure>()),
        (_) => fail('should fail'),
      );
    });
  });
}
