import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/list_card.dart';

void main() {
  final testSummary = ListSummary(
    list: ShoppingList(
      id: 'list-1',
      name: 'Sunday market',
      currency: CurrencyCode.ngn,
      createdAt: DateTime.utc(2026, 10, 12),
      updatedAt: DateTime.utc(2026, 10, 12),
    ),
    itemCount: 5,
    total: const Money(4935000), // ₦49,350.00
  );

  testWidgets('ListCard displays name, items, date, and formatted total',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListCard(
            summary: testSummary,
            onTap: () {},
            onRename: () {},
            onChangeCurrency: () {},
            onDuplicate: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Sunday market'), findsOneWidget);
    expect(find.text('5 items • Updated 12 Oct 2026'), findsOneWidget);
    expect(find.text('₦49,350.00'), findsOneWidget);
  });

  testWidgets('ListCard tap triggers onTap callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListCard(
            summary: testSummary,
            onTap: () => tapped = true,
            onRename: () {},
            onChangeCurrency: () {},
            onDuplicate: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sunday market'));
    expect(tapped, isTrue);
  });

  testWidgets('ListCard popup menu triggers actions', (tester) async {
    var renamed = false;
    var currencyChanged = false;
    var duplicated = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListCard(
            summary: testSummary,
            onTap: () {},
            onRename: () => renamed = true,
            onChangeCurrency: () => currencyChanged = true,
            onDuplicate: () => duplicated = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    // Test Rename
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(renamed, isTrue);

    // Test Change currency
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change currency'));
    await tester.pumpAndSettle();
    expect(currencyChanged, isTrue);

    // Test Duplicate
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(duplicated, isTrue);

    // Test Delete
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}
