import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/formatting/quantity_formatter.dart';

void main() {
  group('QuantityFormatter tests', () {
    test(
        'FR-021/AS-02 formats quantity with up to 3 decimals and no trailing zeros per section 7.6',
        () {
      expect(QuantityFormatter.format(const Quantity(2500)), '2.5');
      expect(QuantityFormatter.format(const Quantity(2000)), '2');
      expect(QuantityFormatter.format(const Quantity(125)), '0.125');
      expect(QuantityFormatter.format(const Quantity(10)), '0.01');
      expect(QuantityFormatter.format(const Quantity(5)), '0.005');
      expect(QuantityFormatter.format(const Quantity(9999999)), '9,999.999');
      expect(QuantityFormatter.format(const Quantity(0)), '0');
    });

    test('FR-021 throws ArgumentError on negative quantity', () {
      expect(
        () => QuantityFormatter.formatMilli(-1),
        throwsArgumentError,
      );
    });
  });
}
