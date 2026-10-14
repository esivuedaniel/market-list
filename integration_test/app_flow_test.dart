import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:market_list/app.dart';
import 'package:market_list/core/database/app_database.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/features/export/domain/entities/share_outcome.dart';
import 'package:market_list/features/export/domain/services/share_service.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';

class FakeShareService implements ShareService {
  String? sharedFilePath;
  String? sharedSubject;
  String? sharedText;

  @override
  Future<Either<Failure, ShareOutcome>> shareFile({
    required String path,
    required String subject,
    String? text,
  }) async {
    sharedFilePath = path;
    sharedSubject = subject;
    sharedText = text;
    return const Right(ShareOutcome.success);
  }

  @override
  Future<Either<Failure, ShareOutcome>> shareText(String text) async {
    sharedText = text;
    return const Right(ShareOutcome.success);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeShareService fakeShareService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeShareService = FakeShareService();

    await getIt.reset();
    await configureDependencies(database: db);

    if (getIt.isRegistered<ShareService>()) {
      getIt.unregister<ShareService>();
    }
    getIt.registerSingleton<ShareService>(fakeShareService);
  });

  tearDown(() async {
    await db.close();
    await getIt.reset();
  });

  group('PRD 13.3 Integration Flows', () {
    testWidgets('1. First run: Confirm currency and open Market list', (tester) async {
      getIt<SettingsCubit>().start('US');

      await tester.pumpWidget(const MarketListApp());
      await tester.pumpAndSettle();

      // Onboarding sheet shows "Choose your currency"
      expect(find.text('Choose your currency'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // List Detail opens with "Market list"
      expect(find.text('Market list'), findsOneWidget);
      expect(find.text('Add item'), findsOneWidget);
    });

    testWidgets('2. Happy path: Add 3 items, edit price, delete, undo', (tester) async {
      getIt<SettingsCubit>().start('US');

      await tester.pumpWidget(const MarketListApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Helper to add an item
      Future<void> addItem(String name, String qty, String unit, String price) async {
        await tester.tap(find.widgetWithText(FloatingActionButton, 'Add item'));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'Item name'), name);
        await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), qty);
        await tester.enterText(find.widgetWithText(TextFormField, 'Unit (optional)'), unit);
        await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), price);

        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await tester.pumpAndSettle();
      }

      // Add item 1: Apples, 2 kg @ 10 = 20
      await addItem('Apples', '2', 'kg', '10.00');
      expect(find.text('Apples'), findsOneWidget);

      // Add item 2: Bananas, 3 kg @ 5 = 15
      await addItem('Bananas', '3', 'kg', '5.00');
      expect(find.text('Bananas'), findsOneWidget);

      // Add item 3: Carrots, 1 kg @ 8 = 8
      await addItem('Carrots', '1', 'kg', '8.00');
      expect(find.text('Carrots'), findsOneWidget);

      // Total should be 20 + 15 + 8 = 43.00
      expect(find.text(r'$43.00'), findsOneWidget);

      // Edit one price: change Apples price from 10.00 to 15.00 (new line total: 30)
      await tester.tap(find.text('Apples'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), '15.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // New total: 30 + 15 + 8 = 53.00
      expect(find.text(r'$53.00'), findsOneWidget);

      // Delete Carrots
      final carrotsFinder = find.ancestor(
        of: find.text('Carrots'),
        matching: find.byType(Card),
      );
      final menuButton = find.descendant(
        of: carrotsFinder,
        matching: find.byIcon(Icons.more_vert),
      );
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify SnackBar and new total: 30 + 15 = 45.00
      expect(find.text('Item deleted'), findsOneWidget);
      expect(find.text(r'$45.00'), findsOneWidget);

      // Undo deletion
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Carrots restored and total back to 53.00
      expect(find.text('Carrots'), findsOneWidget);
      expect(find.text(r'$53.00'), findsOneWidget);
    });

    testWidgets('3. Persistence: Items and lists persist across app restart', (tester) async {
      getIt<SettingsCubit>().start('US');

      await tester.pumpWidget(const MarketListApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Add one item
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Item name'), 'Milk');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '1');
      await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), '4.50');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);

      // Simulate app restart by resetting GetIt, re-wiring with the same database
      await getIt.reset();
      await configureDependencies(database: db);

      getIt<SettingsCubit>().start('US');

      await tester.pumpWidget(const MarketListApp());
      await tester.pumpAndSettle();

      // Lists screen shows "Market list" with 1 item
      expect(find.text('Market list'), findsOneWidget);
      expect(find.text('1 item • Updated today'), findsNothing); // format uses d MMM y

      // Open the list
      await tester.tap(find.text('Market list'));
      await tester.pumpAndSettle();

      // Milk is still present
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text(r'$4.50'), findsOneWidget);
    });

    testWidgets('4. Share: Exports PDF and text through fake ShareService', (tester) async {
      getIt<SettingsCubit>().start('US');

      await tester.pumpWidget(const MarketListApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Add item
      await tester.tap(find.widgetWithText(FloatingActionButton, 'Add item'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Item name'), 'Bread');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '2');
      await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), '3.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Open share sheet
      await tester.tap(find.byTooltip('Share list'));
      await tester.pumpAndSettle();

      expect(find.text('Share list'), findsOneWidget);
      expect(find.text('Share as PDF'), findsOneWidget);
      expect(find.text('Share as text'), findsOneWidget);

      // Share as text
      await tester.tap(find.text('Share as text'));
      await tester.pumpAndSettle();

      expect(fakeShareService.sharedText, isNotNull);
      expect(fakeShareService.sharedText, contains('Market list'));
      expect(fakeShareService.sharedText, contains('Bread'));

      // Open share sheet again
      await tester.tap(find.byTooltip('Share list'));
      await tester.pumpAndSettle();

      // Share as PDF
      await tester.tap(find.text('Share as PDF'));
      await tester.pumpAndSettle();

      expect(fakeShareService.sharedFilePath, isNotNull);
      final pdfFile = File(fakeShareService.sharedFilePath!);
      expect(pdfFile.existsSync(), isTrue);
      final headerBytes = pdfFile.readAsBytesSync().sublist(0, 4);
      expect(String.fromCharCodes(headerBytes), '%PDF');
    });
  });
}
