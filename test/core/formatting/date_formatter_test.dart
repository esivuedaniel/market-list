import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/formatting/date_formatter.dart';

void main() {
  group('DateFormatter tests', () {
    test('FR-072 formats dates as d MMM y per section 7.6', () {
      final date = DateTime(2026, 10, 12, 14, 30);
      expect(DateFormatter.format(date), '12 Oct 2026');
    });

    test('FR-072 formats epoch milliseconds correctly', () {
      final date = DateTime(2026, 1, 5, 10, 0);
      expect(DateFormatter.formatEpochMs(date.millisecondsSinceEpoch), '5 Jan 2026');
    });
  });
}
