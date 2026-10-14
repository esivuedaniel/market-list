import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/theme/app_theme.dart';

void main() {
  testWidgets('MarketListApp renders placeholder screen with orange primary',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MarketListApp());

    expect(find.text('Market List'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    final scaffold = tester.firstWidget<Scaffold>(find.byType(Scaffold));
    final appBar = scaffold.appBar as AppBar?;
    expect(appBar, isNotNull);
    expect(appBar!.backgroundColor, AppTheme.lightPrimary);
  });
}
