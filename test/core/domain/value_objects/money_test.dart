import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

void main() {
  group('Money value object tests', () {
    test('FR-061 rounding example 1: 2.5 x 1500.00 = 3750.00 exact', () {
      final q = Quantity.parse('2.5'); // 2500 milli
      final p = Money.parse('1500.00'); // 150000 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 375000); // 3,750.00
    });

    test('FR-061 rounding example 2: 0.333 x 10.00 = 3.33', () {
      final q = Quantity.parse('0.333'); // 333 milli
      final p = Money.parse('10.00'); // 1000 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 333); // 3.33
    });

    test('FR-061 rounding example 3: 0.005 x 1.00 = 0.01 rounds half up', () {
      final q = Quantity.parse('0.005'); // 5 milli
      final p = Money.parse('1.00'); // 100 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 1); // 0.01
    });

    test('FR-061 rounding example 4: 0.004 x 1.00 = 0.00 rounds down', () {
      final q = Quantity.parse('0.004'); // 4 milli
      final p = Money.parse('1.00'); // 100 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 0); // 0.00
    });

    test('FR-061 rounding example 5: 3 x 0.99 = 2.97 exact', () {
      final q = Quantity.parse('3'); // 3000 milli
      final p = Money.parse('0.99'); // 99 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 297); // 2.97
    });

    test(
        'FR-061 rounding example 6: 9,999.999 x 99,999,999.99 maximum check no overflow',
        () {
      final q = Quantity.parse('9999.999'); // 9,999,999 milli
      final p = Money.parse('99999999.99'); // 9,999,999,999 minor
      final line = Money.calculateLineTotal(quantity: q, unitPrice: p);
      expect(line.minor, 99999989990000); // 999,999,899,900.00
    });

    test(
        'G2/FR-062 BigInt cross-check on 500 random items matches int line total and list sum',
        () {
      final random = math.Random(42);
      var totalInt = 0;
      var totalBigInt = BigInt.zero;

      for (var i = 0; i < 500; i++) {
        // Random milli: 1 to 9,999,999
        final milli = 1 + random.nextInt(AppLimits.maxQuantityMilli);
        // Random minor: 0 to 9,999,999 (up to 99,999.99 to model normal items)
        final minor = random.nextInt(10000000);

        final q = Quantity(milli);
        final p = Money(minor);
        final line = Money.calculateLineTotal(quantity: q, unitPrice: p);

        // Independent BigInt calculation:
        final bQ = BigInt.from(milli);
        final bP = BigInt.from(minor);
        final bLine =
            (bQ * bP + BigInt.from(500)) ~/ BigInt.from(1000);

        expect(line.minor, bLine.toInt(),
            reason: 'Mismatch for milli=$milli, minor=$minor');

        totalInt += line.minor;
        totalBigInt += bLine;
      }

      expect(totalInt, totalBigInt.toInt());
    });

    test('AS-04/AS-06 parse handles various decimal formats without double', () {
      expect(Money.tryParse('1500.5')?.minor, 150050);
      expect(Money.tryParse('1500.50')?.minor, 150050);
      expect(Money.tryParse('1500')?.minor, 150000);
      expect(Money.tryParse('0')?.minor, 0);
      expect(Money.tryParse('0.00')?.minor, 0);
      expect(Money.tryParse('0.05')?.minor, 5);
      expect(Money.tryParse('.5')?.minor, 50);

      // Rejects more than 2 decimals:
      expect(Money.tryParse('1.234'), isNull);
      // Rejects negative amounts:
      expect(Money.tryParse('-10'), isNull);
      // Rejects non-digits:
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('1.2.3'), isNull);
    });

    test('AS-03 Money arithmetic, comparisons, and limits', () {
      const m1 = Money(100);
      const m2 = Money(250);

      expect((m1 + m2).minor, 350);
      expect((m2 - m1).minor, 150);
      expect(m1 < m2, isTrue);
      expect(m1 <= m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m2 >= m1, isTrue);
      expect(m1.compareTo(m2), isNegative);
      expect(m1 == const Money(100), isTrue);
      expect(m1.props, [100]);
      expect(m1.toString(), 'Money(100 minor)');
      expect(Money.zero.minor, 0);

      expect(() => Money.parse('invalid'), throwsFormatException);
      expect(const Money.fromMinor(100).minor, 100);

      expect(const Money(0).isValid, isTrue);
      expect(const Money(9999999999).isValid, isTrue);
      expect(const Money(-1).isValid, isFalse);
      expect(const Money(10000000000).isValid, isFalse);
    });
  });
}

