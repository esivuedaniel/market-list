import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders title, message, icon, and button',
      (tester) async {
    var actionCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'No lists yet',
            message: 'Create a list to get started.',
            buttonText: 'Create your first list',
            onAction: () => actionCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('No lists yet'), findsOneWidget);
    expect(find.text('Create a list to get started.'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
    expect(find.text('Create your first list'), findsOneWidget);

    await tester.tap(find.text('Create your first list'));
    expect(actionCalled, isTrue);
  });
}
