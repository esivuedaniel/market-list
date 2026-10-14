import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';

void main() {
  group('AS-05 CurrencyCode tests', () {
    test('AS-05 exactly 7 currencies with correct symbols', () {
      expect(CurrencyCode.values.length, 7);
      expect(CurrencyCode.ngn.symbol, '₦');
      expect(CurrencyCode.ghs.symbol, 'GH₵');
      expect(CurrencyCode.kes.symbol, 'KSh');
      expect(CurrencyCode.zar.symbol, 'R');
      expect(CurrencyCode.usd.symbol, r'$');
      expect(CurrencyCode.gbp.symbol, '£');
      expect(CurrencyCode.eur.symbol, '€');
    });

    test('AS-05 tryParse and parse', () {
      expect(CurrencyCode.tryParse('NGN'), CurrencyCode.ngn);
      expect(CurrencyCode.tryParse('ngn'), CurrencyCode.ngn);
      expect(CurrencyCode.tryParse(' usd '), CurrencyCode.usd);
      expect(CurrencyCode.tryParse('XYZ'), isNull);
      expect(CurrencyCode.tryParse(null), isNull);

      expect(CurrencyCode.parse('EUR'), CurrencyCode.eur);
      expect(() => CurrencyCode.parse('INVALID'), throwsArgumentError);
    });

    test('AS-05/FR-092 fromCountryCode maps regions correctly and defaults to USD', () {
      expect(CurrencyCode.fromCountryCode('NG'), CurrencyCode.ngn);
      expect(CurrencyCode.fromCountryCode('GH'), CurrencyCode.ghs);
      expect(CurrencyCode.fromCountryCode('KE'), CurrencyCode.kes);
      expect(CurrencyCode.fromCountryCode('ZA'), CurrencyCode.zar);
      expect(CurrencyCode.fromCountryCode('US'), CurrencyCode.usd);
      expect(CurrencyCode.fromCountryCode('GB'), CurrencyCode.gbp);
      expect(CurrencyCode.fromCountryCode('DE'), CurrencyCode.eur);
      expect(CurrencyCode.fromCountryCode('FR'), CurrencyCode.eur);
      expect(CurrencyCode.fromCountryCode('ES'), CurrencyCode.eur);
      expect(CurrencyCode.fromCountryCode('IT'), CurrencyCode.eur);
      expect(CurrencyCode.fromCountryCode('XX'), CurrencyCode.usd);
      expect(CurrencyCode.fromCountryCode(null), CurrencyCode.usd);
    });
  });
}
