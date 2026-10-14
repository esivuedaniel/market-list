import 'package:equatable/equatable.dart';
import 'package:market_list/core/constants/app_limits.dart';

class Quantity extends Equatable {
  const Quantity(this.milli);
  const Quantity.fromMilli(this.milli);

  final int milli;

  static const Quantity zero = Quantity(0);

  bool get isValid =>
      milli >= AppLimits.minQuantityMilli && milli <= AppLimits.maxQuantityMilli;

  static Quantity? tryParse(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final dotCount = trimmed.split('.').length - 1;
    if (dotCount > 1) return null;

    final parts = trimmed.split('.');
    final wholeStr = parts[0];
    final fracStr = parts.length > 1 ? parts[1] : '';

    if (fracStr.length > 3) return null;

    if (wholeStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(wholeStr)) {
      return null;
    }
    if (fracStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fracStr)) {
      return null;
    }

    final whole = wholeStr.isEmpty ? 0 : int.tryParse(wholeStr);
    if (whole == null || whole < 0) return null;

    final paddedFrac = fracStr.padRight(3, '0');
    final frac = paddedFrac.isEmpty ? 0 : int.tryParse(paddedFrac);
    if (frac == null || frac < 0) return null;

    final totalMilli = whole * 1000 + frac;
    return Quantity(totalMilli);
  }

  static Quantity parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Invalid quantity format: $input');
    }
    return parsed;
  }

  @override
  List<Object?> get props => [milli];

  @override
  String toString() => 'Quantity($milli milli)';
}
