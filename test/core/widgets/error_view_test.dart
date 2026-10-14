import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/widgets/error_view.dart';

void main() {
  testWidgets('ErrorView renders message, icon, and handles retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'An error occurred.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('An error occurred.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
