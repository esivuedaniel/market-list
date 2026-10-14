import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/platform/clock.dart';

void main() {
  group('Clock tests', () {
    test('FR-080 Clock returns UTC time and epoch milliseconds', () {
      const clock = Clock();
      final now = clock.now();
      final epochMs = clock.nowEpochMs();

      expect(now.isUtc, isTrue);
      expect(epochMs, greaterThan(0));
      expect(
        (now.millisecondsSinceEpoch - epochMs).abs(),
        lessThanOrEqualTo(50),
      );
    });
  });
}
