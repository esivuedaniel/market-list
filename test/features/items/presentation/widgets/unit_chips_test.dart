import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/features/items/presentation/widgets/unit_chips.dart';

void main() {
  group('DecimalTextInputFormatter', () {
    test('FR-011 allows valid integers and decimals within limit', () {
      const formatter2 = DecimalTextInputFormatter(decimalDigits: 2);
      const formatter3 = DecimalTextInputFormatter(decimalDigits: 3);

      const oldVal = TextEditingValue.empty;

      expect(
        formatter2
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '12.5'),
            )
            .text,
        '12.5',
      );

      expect(
        formatter2
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '12.50'),
            )
            .text,
        '12.50',
      );

      // 3 decimals rejected for decimalDigits: 2
      expect(
        formatter2
            .formatEditUpdate(
              const TextEditingValue(text: '12.50'),
              const TextEditingValue(text: '12.505'),
            )
            .text,
        '12.50',
      );

      // 3 decimals accepted for decimalDigits: 3
      expect(
        formatter3
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '12.505'),
            )
            .text,
        '12.505',
      );

      // 4 decimals rejected for decimalDigits: 3
      expect(
        formatter3
            .formatEditUpdate(
              const TextEditingValue(text: '12.505'),
              const TextEditingValue(text: '12.5055'),
            )
            .text,
        '12.505',
      );
    });

    test('FR-011 paste with comma, negative, or multiple dots keeps old text', () {
      const formatter = DecimalTextInputFormatter(decimalDigits: 2);
      const oldVal = TextEditingValue(text: '15');

      // Paste with comma
      expect(
        formatter
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '1,500'),
            )
            .text,
        '15',
      );

      // Paste with minus sign
      expect(
        formatter
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '-15'),
            )
            .text,
        '15',
      );

      // Two dots
      expect(
        formatter
            .formatEditUpdate(
              oldVal,
              const TextEditingValue(text: '15.5.5'),
            )
            .text,
        '15',
      );
    });
  });

  group('UnitChips', () {
    testWidgets('FR-016 renders quick-pick chips and handles tap', (tester) async {
      String? tappedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitChips(
              selectedUnit: 'kg',
              onSelected: (u) => tappedUnit = u,
            ),
          ),
        ),
      );

      expect(find.text('kg'), findsOneWidget);
      expect(find.text('g'), findsOneWidget);
      expect(find.text('pcs'), findsOneWidget);
      expect(find.text('bag'), findsOneWidget);
      expect(find.text('bunch'), findsOneWidget);
      expect(find.text('litre'), findsOneWidget);
      expect(find.text('crate'), findsOneWidget);

      await tester.tap(find.text('pcs'));
      expect(tappedUnit, 'pcs');
    });
  });
}
