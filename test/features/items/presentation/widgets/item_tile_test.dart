import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/presentation/widgets/item_tile.dart';

void main() {
  final testDate = DateTime.utc(2026, 10, 14);

  final unboughtItem = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity.fromMilli(2500),
    unit: 'kg',
    unitPrice: const Money.fromMinor(150000),
    isBought: false,
    createdAt: testDate,
    updatedAt: testDate,
  );

  final boughtItem = unboughtItem.copyWith(isBought: true);

  testWidgets('ItemTile FR-020 displays details and semantics for not bought item',
      (tester) async {
    bool? toggledVal;
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemTile(
            item: unboughtItem,
            currency: CurrencyCode.ngn,
            onTap: () => tapped = true,
            onBoughtToggled: (val) => toggledVal = val,
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tomatoes'), findsOneWidget);
    expect(find.text('2.5 kg x ₦1,500.00'), findsOneWidget);
    expect(find.text('₦3,750.00'), findsOneWidget);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    expect(toggledVal, isTrue);

    await tester.tap(find.text('Tomatoes'));
    expect(tapped, isTrue);

    // Semantics check NFR-012
    expect(
      find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.label ==
              'Tomatoes, 2.5 kg, ₦1,500.00 each, total ₦3,750.00, not bought'),
      findsOneWidget,
    );
  });

  testWidgets('ItemTile FR-050 displays struck-through styling and semantics for bought item',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemTile(
            item: boughtItem,
            currency: CurrencyCode.ngn,
            onTap: () {},
            onBoughtToggled: (_) {},
            onDelete: () {},
          ),
        ),
      ),
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);

    final nameText = tester.widget<Text>(find.text('Tomatoes'));
    expect(nameText.style?.decoration, TextDecoration.lineThrough);

    expect(
      find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.label ==
              'Tomatoes, 2.5 kg, ₦1,500.00 each, total ₦3,750.00, bought'),
      findsOneWidget,
    );
  });

  testWidgets('ItemTile FR-040 popup menu options and swipe to delete',
      (tester) async {
    bool editCalled = false;
    bool deleteCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemTile(
            item: unboughtItem,
            currency: CurrencyCode.ngn,
            onTap: () => editCalled = true,
            onBoughtToggled: (_) {},
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    // Open popup menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(editCalled, isTrue);

    // Swipe dismissible to delete
    await tester.drag(find.text('Tomatoes'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(deleteCalled, isTrue);
  });
}
