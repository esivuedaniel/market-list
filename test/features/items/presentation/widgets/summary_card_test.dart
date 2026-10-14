import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/items/presentation/widgets/summary_card.dart';

void main() {
  testWidgets('SummaryCard FR-060 displays formatted total, currency code, and bought count',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            total: Money.fromMinor(425000),
            currency: CurrencyCode.ngn,
            boughtCount: 2,
            itemCount: 5,
          ),
        ),
      ),
    );

    expect(find.text('Total (NGN)'), findsOneWidget);
    expect(find.text('₦4,250.00'), findsOneWidget);
    expect(find.text('2 of 5 bought'), findsOneWidget);
    expect(find.byType(FittedBox), findsOneWidget);
  });

  testWidgets('SummaryCard FR-062 displays 0.00 when list is empty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            total: Money.zero,
            currency: CurrencyCode.usd,
            boughtCount: 0,
            itemCount: 0,
          ),
        ),
      ),
    );

    expect(find.text('Total (USD)'), findsOneWidget);
    expect(find.text(r'$0.00'), findsOneWidget);
    expect(find.text('0 of 0 bought'), findsOneWidget);
  });
}
