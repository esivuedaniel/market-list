import 'package:equatable/equatable.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

class Money extends Equatable implements Comparable<Money> {
  const Money(this.minor);

  final int minor;

  static const Money zero = Money(0);

  bool get isValid =>
      minor >= AppLimits.minUnitPriceMinor &&
      minor <= AppLimits.maxUnitPriceMinor;

  static Money calculateLineTotal({
    required Quantity quantity,
    required Money unitPrice,
  }) {
    final lineMinor = (quantity.milli * unitPrice.minor + 500) ~/ 1000;
    return Money(lineMinor);
  }

  static Money? tryParse(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final dotCount = trimmed.split('.').length - 1;
    if (dotCount > 1) return null;

    final parts = trimmed.split('.');
    final wholeStr = parts[0];
    final fracStr = parts.length > 1 ? parts[1] : '';

    if (fracStr.length > 2) return null;

    if (wholeStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(wholeStr)) {
      return null;
    }
    if (fracStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracStr)) {
      return null;
    }

    final whole = wholeStr.isEmpty ? 0 : int.tryParse(wholeStr);
    if (whole == null || whole < 0) return null;

    final paddedFrac = fracStr.padRight(2, '0');
    final frac = paddedFrac.isEmpty ? 0 : int.tryParse(paddedFrac);
    if (frac == null || frac < 0) return null;

    final totalMinor = whole * 100 + frac;
    return Money(totalMinor);
  }

  static Money parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Invalid money format: $input');
    }
    return parsed;
  }

  Money operator +(Money other) => Money(minor + other.minor);
  Money operator -(Money other) => Money(minor - other.minor);

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  bool operator <(Money other) => minor < other.minor;
  bool operator <=(Money other) => minor <= other.minor;
  bool operator >(Money other) => minor > other.minor;
  bool operator >=(Money other) => minor >= other.minor;

  @override
  List<Object?> get props => [minor];

  @override
  String toString() => 'Money($minor minor)';
}
