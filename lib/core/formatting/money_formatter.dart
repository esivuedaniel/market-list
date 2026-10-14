import 'package:intl/intl.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';

class MoneyFormatter {
  const MoneyFormatter._();

  static final NumberFormat _integerFormatter =
      NumberFormat('#,##0', 'en_US');

  /// Formats money using intl grouping for the whole part and appending a 2-digit fraction.
  /// Never passes the amount through `double`.
  /// Formatter takes currency as a parameter and reads no global state.
  static String format(Money money, CurrencyCode currency) {
    return formatMinor(money.minor, currency);
  }

  static String formatMinor(int minor, CurrencyCode currency) {
    if (minor < 0) {
      throw ArgumentError.value(minor, 'minor', 'Negative amounts cannot occur');
    }

    final whole = minor ~/ 100;
    final fraction = minor % 100;

    final formattedWhole = _integerFormatter.format(whole);
    final formattedFraction = fraction.toString().padLeft(2, '0');

    return '${currency.symbol}$formattedWhole.$formattedFraction';
  }
}
