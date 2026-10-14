import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/currency_picker_dialog.dart';

void main() {
  testWidgets('CurrencyPickerDialog displays 7 currencies and picks one',
      (tester) async {
    CurrencyCode? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<CurrencyCode>(
                  context: context,
                  builder: (_) => const CurrencyPickerDialog(
                    currentCurrency: CurrencyCode.ngn,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Change currency'), findsOneWidget);
    for (final code in CurrencyCode.values) {
      expect(find.text('${code.symbol}  ${code.code}'), findsOneWidget);
    }

    await tester.tap(find.text('€  EUR'));
    await tester.pumpAndSettle();

    expect(result, CurrencyCode.eur);
  });

  testWidgets('CurrencyPickerDialog cancel pops without result',
      (tester) async {
    CurrencyCode? result = CurrencyCode.usd;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<CurrencyCode>(
                  context: context,
                  builder: (_) => const CurrencyPickerDialog(
                    currentCurrency: CurrencyCode.ngn,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
