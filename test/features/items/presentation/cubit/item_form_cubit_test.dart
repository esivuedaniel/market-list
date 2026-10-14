import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';
import 'package:market_list/features/items/domain/usecases/get_item.dart';
import 'package:market_list/features/items/domain/usecases/has_duplicate_item_name.dart';
import 'package:market_list/features/items/domain/usecases/update_item.dart';
import 'package:market_list/features/items/domain/usecases/validate_item_draft.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_cubit.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAddItem extends Mock implements AddItem {}

class MockUpdateItem extends Mock implements UpdateItem {}

class MockGetItem extends Mock implements GetItem {}

class MockDeleteItem extends Mock implements DeleteItem {}

class MockHasDuplicateItemName extends Mock implements HasDuplicateItemName {}

void main() {
  late MockAddItem mockAddItem;
  late MockUpdateItem mockUpdateItem;
  late MockGetItem mockGetItem;
  late MockDeleteItem mockDeleteItem;
  late MockHasDuplicateItemName mockHasDuplicateItemName;
  const validateItemDraft = ValidateItemDraft();

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

  setUpAll(() {
    registerFallbackValue(
      const AddItemParams(
        listId: 'list-1',
        draft: ItemDraft(
          name: 'Tomatoes',
          quantity: Quantity(1000),
          unitPrice: Money(1000),
        ),
      ),
    );
    registerFallbackValue(
      const UpdateItemParams(
        itemId: 'item-1',
        draft: ItemDraft(
          name: 'Tomatoes',
          quantity: Quantity(1000),
          unitPrice: Money(1000),
        ),
      ),
    );
    registerFallbackValue(
      const DuplicateCheckParams(
        listId: 'list-1',
        name: 'Tomatoes',
      ),
    );
  });

  setUp(() {
    mockAddItem = MockAddItem();
    mockUpdateItem = MockUpdateItem();
    mockGetItem = MockGetItem();
    mockDeleteItem = MockDeleteItem();
    mockHasDuplicateItemName = MockHasDuplicateItemName();
  });

  ItemFormCubit createCubit({String? itemId}) {
    return ItemFormCubit(
      listId: 'list-1',
      itemId: itemId,
      initialCurrency: CurrencyCode.ngn,
      addItem: mockAddItem,
      updateItem: mockUpdateItem,
      getItem: mockGetItem,
      deleteItem: mockDeleteItem,
      hasDuplicateItemName: mockHasDuplicateItemName,
      validateItemDraft: validateItemDraft,
    );
  }

  group('ItemFormCubit - Add Mode', () {
    test('FR-010 initial state is ready with add mode and currency', () {
      final cubit = createCubit();
      expect(cubit.state.status, ItemFormStatus.ready);
      expect(cubit.state.isEdit, isFalse);
      expect(cubit.state.currency, CurrencyCode.ngn);
    });

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-013 field updates calculate preview and mark dirty',
      build: createCubit,
      act: (cubit) {
        cubit.nameChanged('Tomatoes');
        cubit.quantityChanged('2.5');
        cubit.priceChanged('1500');
        cubit.unitChipSelected('kg');
        cubit.fieldBlurred(ItemFormField.name);
      },
      expect: () => [
        isA<ItemFormState>()
            .having((s) => s.name, 'name', 'Tomatoes')
            .having((s) => s.isDirty, 'isDirty', true),
        isA<ItemFormState>()
            .having((s) => s.quantityText, 'quantity', '2.5')
            .having((s) => s.linePreview, 'linePreview', isNull),
        isA<ItemFormState>()
            .having((s) => s.priceText, 'price', '1500')
            .having(
              (s) => s.linePreview,
              'linePreview',
              const Money(375000), // 2.5 * 1500 = 3,750.00
            ),
        isA<ItemFormState>()
            .having((s) => s.unit, 'unit', 'kg'),
        isA<ItemFormState>()
            .having((s) => s.touched, 'touched', {ItemFormField.name}),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-011 submit with invalid input sets showErrors and stays ready',
      build: createCubit,
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<ItemFormState>()
            .having((s) => s.showErrors, 'showErrors', true)
            .having((s) => s.status, 'status', ItemFormStatus.ready)
            .having((s) => s.errors.hasErrors, 'hasErrors', true),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-015 duplicate check triggers duplicateWarning in add mode',
      build: () {
        when(() => mockHasDuplicateItemName(any()))
            .thenAnswer((_) async => const Right(true));
        return createCubit();
      },
      seed: () => const ItemFormState(
        name: 'Tomatoes',
        quantityText: '2',
        priceText: '500',
        currency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.duplicateWarning)
            .having((s) => s.showErrors, 'showErrors', true),
      ],
      verify: (_) {
        verify(() => mockHasDuplicateItemName(any())).called(1);
        verifyNever(() => mockAddItem(any()));
      },
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-015 cancelDuplicate returns to ready',
      build: createCubit,
      seed: () => const ItemFormState(
        status: ItemFormStatus.duplicateWarning,
        name: 'Tomatoes',
      ),
      act: (cubit) => cubit.cancelDuplicate(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.ready),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-010 save success emits submitting then saved',
      build: () {
        when(() => mockHasDuplicateItemName(any()))
            .thenAnswer((_) async => const Right(false));
        when(() => mockAddItem(any()))
            .thenAnswer((_) async => Right(testItem));
        return createCubit();
      },
      seed: () => const ItemFormState(
        name: 'Tomatoes',
        quantityText: '2.5',
        unit: 'kg',
        priceText: '1500',
        currency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.submitting),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.saved)
            .having((s) => s.isDirty, 'isDirty', false),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-012 save and add another emits savedAndReset with cleared fields',
      build: () {
        when(() => mockHasDuplicateItemName(any()))
            .thenAnswer((_) async => const Right(false));
        when(() => mockAddItem(any()))
            .thenAnswer((_) async => Right(testItem));
        return createCubit();
      },
      seed: () => const ItemFormState(
        name: 'Tomatoes',
        quantityText: '2.5',
        unit: 'kg',
        priceText: '1500',
        currency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.submit(addAnother: true),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.submitting),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.savedAndReset)
            .having((s) => s.name, 'name', '')
            .having((s) => s.quantityText, 'quantity', '')
            .having((s) => s.unit, 'unit', isNull)
            .having((s) => s.priceText, 'price', '')
            .having((s) => s.showErrors, 'showErrors', false)
            .having((s) => s.touched, 'touched', isEmpty),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-014 save failure with limit emits failure message and keeps values',
      build: () {
        when(() => mockHasDuplicateItemName(any()))
            .thenAnswer((_) async => const Right(false));
        when(() => mockAddItem(any()))
            .thenAnswer((_) async => const Left(LimitFailure(LimitKind.items)));
        return createCubit();
      },
      seed: () => const ItemFormState(
        name: 'Tomatoes',
        quantityText: '2.5',
        priceText: '1500',
        currency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.submitting),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.failure)
            .having((s) => s.message, 'message', FailureMessages.listItemsLimitReached)
            .having((s) => s.name, 'name', 'Tomatoes'),
      ],
    );
  });

  group('ItemFormCubit - Edit Mode', () {
    test('FR-030 initial state is loading with isEdit: true', () {
      final cubit = createCubit(itemId: 'item-1');
      expect(cubit.state.status, ItemFormStatus.loading);
      expect(cubit.state.isEdit, isTrue);
    });

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-030 load loads item values and computes line preview',
      build: () {
        when(() => mockGetItem('item-1')).thenAnswer((_) async => Right(testItem));
        return createCubit(itemId: 'item-1');
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.loading),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.ready)
            .having((s) => s.isEdit, 'isEdit', true)
            .having((s) => s.name, 'name', 'Tomatoes')
            .having((s) => s.quantityText, 'quantityText', '2.5')
            .having((s) => s.unit, 'unit', 'kg')
            .having((s) => s.priceText, 'priceText', '1500')
            .having((s) => s.linePreview, 'preview', const Money(375000))
            .having((s) => s.isDirty, 'isDirty', false),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-030 load failure emits failure with itemLoadFailed message',
      build: () {
        when(() => mockGetItem('item-1'))
            .thenAnswer((_) async => const Left(NotFoundFailure()));
        return createCubit(itemId: 'item-1');
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.loading),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.failure)
            .having((s) => s.message, 'message', FailureMessages.itemLoadFailed),
      ],
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-030 update item calls UpdateItem without duplicate check when name unchanged',
      build: () {
        when(() => mockUpdateItem(any())).thenAnswer((_) async => Right(testItem));
        return createCubit(itemId: 'item-1');
      },
      seed: () => ItemFormState(
        status: ItemFormStatus.ready,
        isEdit: true,
        initialItem: testItem,
        name: 'Tomatoes',
        quantityText: '3',
        priceText: '1500',
        currency: CurrencyCode.ngn,
      ),
      act: (cubit) => cubit.submit(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.submitting),
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.saved),
      ],
      verify: (_) {
        verifyNever(() => mockHasDuplicateItemName(any()));
        verify(() => mockUpdateItem(any())).called(1);
      },
    );

    blocTest<ItemFormCubit, ItemFormState>(
      'FR-040 delete calls DeleteItem and emits deleted with item',
      build: () {
        when(() => mockDeleteItem('item-1')).thenAnswer((_) async => Right(testItem));
        return createCubit(itemId: 'item-1');
      },
      seed: () => ItemFormState(
        status: ItemFormStatus.ready,
        isEdit: true,
        initialItem: testItem,
      ),
      act: (cubit) => cubit.delete(),
      expect: () => [
        isA<ItemFormState>().having((s) => s.status, 'status', ItemFormStatus.submitting),
        isA<ItemFormState>()
            .having((s) => s.status, 'status', ItemFormStatus.deleted)
            .having((s) => s.deletedItem, 'deletedItem', testItem),
      ],
    );
  });
}
