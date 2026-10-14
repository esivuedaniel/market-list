import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/items/domain/entities/item_validation_errors.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_cubit.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_state.dart';
import 'package:market_list/features/items/presentation/pages/item_form_page.dart';
import 'package:mocktail/mocktail.dart';

class MockItemFormCubit extends MockCubit<ItemFormState>
    implements ItemFormCubit {}

void main() {
  late MockItemFormCubit mockItemFormCubit;

  final testItem = ShoppingItem(
    id: 'item-1',
    listId: 'list-1',
    name: 'Tomatoes',
    quantity: const Quantity(2500),
    unit: 'kg',
    unitPrice: const Money(150000),
    isBought: false,
    createdAt: DateTime.utc(2026, 10, 12),
    updatedAt: DateTime.utc(2026, 10, 12),
  );

  setUp(() {
    mockItemFormCubit = MockItemFormCubit();
  });

  Widget createWidget({NavigatorObserver? observer}) {
    return MaterialApp(
      navigatorObservers: observer != null ? [observer] : [],
      home: BlocProvider<ItemFormCubit>.value(
        value: mockItemFormCubit,
        child: const ItemFormPage(),
      ),
    );
  }

  group('ItemFormPage', () {
    testWidgets('FR-010 renders Add item form elements in add mode', (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        const ItemFormState(
          status: ItemFormStatus.ready,
          isEdit: false,
          currency: CurrencyCode.ngn,
        ),
      );

      await tester.pumpWidget(createWidget());

      expect(find.text('Add item'), findsOneWidget);
      expect(find.byKey(const Key('item_form_name_field')), findsOneWidget);
      expect(find.byKey(const Key('item_form_quantity_field')), findsOneWidget);
      expect(find.byKey(const Key('item_form_unit_field')), findsOneWidget);
      expect(find.byKey(const Key('item_form_price_field')), findsOneWidget);
      expect(find.byKey(const Key('item_form_save_button')), findsOneWidget);
      expect(
        find.byKey(const Key('item_form_save_add_another_button')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('item_form_cancel_button')), findsOneWidget);
      expect(find.byKey(const Key('item_form_delete_button')), findsNothing);
    });

    testWidgets('FR-030 renders Edit item form elements with Delete in edit mode',
        (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        ItemFormState(
          status: ItemFormStatus.ready,
          isEdit: true,
          initialItem: testItem,
          name: 'Tomatoes',
          quantityText: '2.5',
          unit: 'kg',
          priceText: '1500',
          currency: CurrencyCode.ngn,
          linePreview: const Money(375000),
        ),
      );

      await tester.pumpWidget(createWidget());

      expect(find.text('Edit item'), findsOneWidget);
      expect(find.text('Save and add another'), findsNothing);
      expect(find.byKey(const Key('item_form_delete_button')), findsOneWidget);
      expect(find.text('Line total: ₦3,750.00'), findsOneWidget);
    });

    testWidgets('FR-011 displays field errors when touched or after submit',
        (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        const ItemFormState(
          status: ItemFormStatus.ready,
          errors: ItemValidationErrors(
            nameError: FailureMessages.enterItemName,
            quantityError: FailureMessages.enterQuantity,
          ),
          touched: {ItemFormField.name},
          showErrors: false,
        ),
      );

      await tester.pumpWidget(createWidget());

      expect(find.text(FailureMessages.enterItemName), findsOneWidget);
      // Quantity is not yet touched or showErrors
      expect(find.text(FailureMessages.enterQuantity), findsNothing);
    });

    testWidgets('FR-012 tapping Save and add another calls cubit submit(addAnother: true)',
        (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        const ItemFormState(
          status: ItemFormStatus.ready,
          isEdit: false,
        ),
      );
      when(() => mockItemFormCubit.submit(addAnother: true))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byKey(const Key('item_form_save_add_another_button')));
      verify(() => mockItemFormCubit.submit(addAnother: true)).called(1);
    });

    testWidgets('FR-015 duplicate warning shows dialog with Add anyway and Cancel',
        (tester) async {
      whenListen(
        mockItemFormCubit,
        Stream.fromIterable([
          const ItemFormState(
            status: ItemFormStatus.duplicateWarning,
            name: 'Tomatoes',
          ),
        ]),
        initialState: const ItemFormState(
          status: ItemFormStatus.ready,
          name: 'Tomatoes',
        ),
      );
      when(() => mockItemFormCubit.confirmDuplicate()).thenAnswer((_) async {});
      when(() => mockItemFormCubit.cancelDuplicate()).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Duplicate item'), findsOneWidget);
      expect(
        find.text('Tomatoes is already on this list. Add it again?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Add anyway'));
      verify(() => mockItemFormCubit.confirmDuplicate()).called(1);
    });

    testWidgets('FR-031 discard guard shows dialog when form is dirty', (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        const ItemFormState(
          status: ItemFormStatus.ready,
          isDirty: true,
        ),
      );

      await tester.pumpWidget(createWidget());

      // Scroll to and tap Cancel button
      final cancelButton = find.byKey(const Key('item_form_cancel_button'));
      await tester.ensureVisible(cancelButton);
      await tester.pumpAndSettle();
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      expect(
        find.text('You have unsaved changes. Are you sure you want to discard them?'),
        findsOneWidget,
      );
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('FR-040 delete in edit mode dispatches cubit.delete()',
        (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        ItemFormState(
          status: ItemFormStatus.ready,
          isEdit: true,
          initialItem: testItem,
        ),
      );
      when(() => mockItemFormCubit.delete()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      final deleteButton = find.byKey(const Key('item_form_delete_button'));
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      verify(() => mockItemFormCubit.delete()).called(1);
    });

    testWidgets('NFR-009 and NFR-011 renders without overflow on 320x568 dp screen and text scale 2.0',
        (tester) async {
      when(() => mockItemFormCubit.state).thenReturn(
        const ItemFormState(
          status: ItemFormStatus.ready,
          isEdit: false,
        ),
      );

      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
              size: Size(320, 568),
            ),
            child: BlocProvider<ItemFormCubit>.value(
              value: mockItemFormCubit,
              child: const ItemFormPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Add item'), findsOneWidget);
    });
  });
}
