import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

void main() {
  group('Quantity value object tests', () {
    test('AS-02/AS-06 parses valid decimal strings up to 3 decimals without double',
        () {
      expect(Quantity.tryParse('2.5')?.milli, 2500);
      expect(Quantity.tryParse('0.125')?.milli, 125);
      expect(Quantity.tryParse('2')?.milli, 2000);
      expect(Quantity.tryParse('0.001')?.milli, 1);
      expect(Quantity.tryParse('9999.999')?.milli, 9999999);
      expect(Quantity.tryParse('.5')?.milli, 500);
      expect(Quantity.tryParse('10.')?.milli, 10000);
    });

    test('AS-02 rejects more than 3 decimals', () {
      expect(Quantity.tryParse('1.2345'), isNull);
      expect(Quantity.tryParse('0.0001'), isNull);
    });

    test('AS-06 rejects invalid characters, negative numbers, and empty strings',
        () {
      expect(Quantity.tryParse('-1'), isNull);
      expect(Quantity.tryParse('abc'), isNull);
      expect(Quantity.tryParse(''), isNull);
      expect(Quantity.tryParse('1.2.3'), isNull);
      expect(Quantity.tryParse('1,5'), isNull);
    });

    test('AS-03/AS-09 isValid enforces 0.001 to 9,999.999 bounds', () {
      expect(const Quantity(0).isValid, isFalse);
      expect(const Quantity(AppLimits.minQuantityMilli).isValid, isTrue);
      expect(const Quantity(AppLimits.maxQuantityMilli).isValid, isTrue);
      expect(const Quantity(AppLimits.maxQuantityMilli + 1).isValid, isFalse);
    });

    test('AS-02 parse throws on invalid string', () {
      expect(() => Quantity.parse('invalid'), throwsFormatException);
      expect(const Quantity(2500).props, [2500]);
      expect(const Quantity(2500).toString(), 'Quantity(2500 milli)');
      expect(Quantity.zero.milli, 0);
    });
  });
}

