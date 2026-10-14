import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static final DateFormat _format = DateFormat('d MMM y', 'en_US');

  /// Formats date per PRD 7.6: `d MMM y` (e.g. 12 Oct 2026).
  static String format(DateTime date) {
    return _format.format(date);
  }

  /// Formats UTC epoch milliseconds into `d MMM y`.
  static String formatEpochMs(int epochMs) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return _format.format(dateTime);
  }
}
