import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/list_name_dialog.dart';

void main() {
  testWidgets('ListNameDialog validates empty name and returns valid name',
      (tester) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const ListNameDialog(
                    title: 'New list',
                    initialName: 'Market list',
                    confirmText: 'Create',
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

    expect(find.text('New list'), findsOneWidget);
    expect(find.text('Market list'), findsOneWidget);

    // Clear text and submit -> should show error
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a list name.'), findsOneWidget);
    expect(result, isNull);

    // Enter valid name and submit
    await tester.enterText(find.byType(TextField), '  Weekly groceries  ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(result, 'Weekly groceries');
  });

  testWidgets('ListNameDialog cancel pops without result', (tester) async {
    String? result = 'initial';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const ListNameDialog(
                    title: 'New list',
                    initialName: 'Market list',
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
