import 'package:intl/intl.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

class QuantityFormatter {
  const QuantityFormatter._();

  static final NumberFormat _integerFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats quantity with up to 3 decimals with no trailing zeros: 2.5, 2, 0.125.
  /// Never passes the amount through `double`.
  static String format(Quantity quantity) {
    return formatMilli(quantity.milli);
  }

  static String formatMilli(int milli) {
    if (milli < 0) {
      throw ArgumentError.value(milli, 'milli', 'Negative quantity cannot occur');
    }

    final whole = milli ~/ 1000;
    final fraction = milli % 1000;

    final formattedWhole = _integerFormatter.format(whole);

    if (fraction == 0) {
      return formattedWhole;
    }

    final padded = fraction.toString().padLeft(3, '0');
    final trimmed = padded.replaceAll(RegExp(r'0+$'), '');

    return '$formattedWhole.$trimmed';
  }
}
