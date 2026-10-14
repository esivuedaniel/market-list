import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/formatting/money_formatter.dart';

void main() {
  group('MoneyFormatter tests', () {
    test('FR-060/AS-05 formats money according to section 7.6 specifications',
        () {
      expect(
        MoneyFormatter.format(const Money(150050), CurrencyCode.ngn),
        '₦1,500.50',
      );
      expect(
        MoneyFormatter.format(const Money(0), CurrencyCode.usd),
        r'$0.00',
      );
      expect(
        MoneyFormatter.format(const Money(100), CurrencyCode.gbp),
        '£1.00',
      );
      expect(
        MoneyFormatter.format(const Money(375000), CurrencyCode.ghs),
        'GH₵3,750.00',
      );
      expect(
        MoneyFormatter.format(const Money(250), CurrencyCode.kes),
        'KSh2.50',
      );
      expect(
        MoneyFormatter.format(const Money(5000000), CurrencyCode.zar),
        'R50,000.00',
      );
      expect(
        MoneyFormatter.format(const Money(99999989990000), CurrencyCode.eur),
        '€999,999,899,900.00',
      );
    });

    test('FR-060 throws ArgumentError on negative minor units', () {
      expect(
        () => MoneyFormatter.formatMinor(-1, CurrencyCode.usd),
        throwsArgumentError,
      );
    });
  });
}
