import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/usecases/validate_item_draft.dart';

void main() {
  late ValidateItemDraft validator;

  setUp(() {
    validator = const ValidateItemDraft();
  });

  group('ValidateItemDraft - PRD 12.1 rules', () {
    test('FR-010 returns valid ItemDraft on correct inputs', () {
      final result = validator(const RawItemInput(
        name: '  Tomatoes  ',
        quantityText: '2.5',
        unit: '  kg  ',
        priceText: '1500.50',
      ));

      expect(result.isRight(), isTrue);
      final draft = result.getOrElse((_) => throw StateError('Expected Right'));
      expect(draft.name, 'Tomatoes');
      expect(draft.quantity, const Quantity(2500));
      expect(draft.unit, 'kg');
      expect(draft.unitPrice, const Money(150050));
    });

    test('FR-010 converts empty or whitespace unit to null', () {
      final result = validator(const RawItemInput(
        name: 'Tomatoes',
        quantityText: '1',
        unit: '   ',
        priceText: '10',
      ));

      expect(result.isRight(), isTrue);
      final draft = result.getOrElse((_) => throw StateError('Expected Right'));
      expect(draft.unit, isNull);
    });

    test('FR-010 allows price of 0', () {
      final result = validator(const RawItemInput(
        name: 'Free Item',
        quantityText: '1',
        unit: null,
        priceText: '0',
      ));

      expect(result.isRight(), isTrue);
      final draft = result.getOrElse((_) => throw StateError('Expected Right'));
      expect(draft.unitPrice, Money.zero);
    });

    test('FR-010 decimal variations for price: 1500.5, 1500., .5, 007', () {
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '1500.5'))
            .map((d) => d.unitPrice),
        const Right(Money(150050)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '1500.'))
            .map((d) => d.unitPrice),
        const Right(Money(150000)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '.5'))
            .map((d) => d.unitPrice),
        const Right(Money(50)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '007'))
            .map((d) => d.unitPrice),
        const Right(Money(700)),
      );
    });

    test('FR-010 decimal variations for quantity: 2.5, 2., .5, 007', () {
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '2.5', priceText: '1'))
            .map((d) => d.quantity),
        const Right(Quantity(2500)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '2.', priceText: '1'))
            .map((d) => d.quantity),
        const Right(Quantity(2000)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '.5', priceText: '1'))
            .map((d) => d.quantity),
        const Right(Quantity(500)),
      );
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '007', priceText: '1'))
            .map((d) => d.quantity),
        const Right(Quantity(7000)),
      );
    });

    test('FR-010 validates name required and max length 80', () {
      final emptyResult = validator(const RawItemInput(
        name: '   ',
        quantityText: '1',
        priceText: '1',
      ));
      expect(
        emptyResult.getLeft().toNullable()?.nameError,
        'Enter an item name.',
      );

      final longResult = validator(RawItemInput(
        name: 'A' * 81,
        quantityText: '1',
        priceText: '1',
      ));
      expect(
        longResult.getLeft().toNullable()?.nameError,
        'Item name must be 80 characters or fewer.',
      );
    });

    test('FR-010 validates quantity required, format, >0, and <=9999.999', () {
      // Empty
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '', priceText: '1'))
            .getLeft()
            .toNullable()
            ?.quantityError,
        'Enter a quantity.',
      );

      // Invalid format
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '2.5.5', priceText: '1'))
            .getLeft()
            .toNullable()
            ?.quantityError,
        'Use digits and one dot only, for example 2.5.',
      );

      // More than 3 decimals
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1.2345', priceText: '1'))
            .getLeft()
            .toNullable()
            ?.quantityError,
        'Use digits and one dot only, for example 2.5.',
      );

      // Quantity must be > 0
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '0', priceText: '1'))
            .getLeft()
            .toNullable()
            ?.quantityError,
        'Quantity must be greater than 0.',
      );

      // Quantity <= 9999.999
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '10000', priceText: '1'))
            .getLeft()
            .toNullable()
            ?.quantityError,
        'Quantity cannot be more than 9,999.999.',
      );
    });

    test('FR-010 validates unit max length 20', () {
      final longUnitResult = validator(RawItemInput(
        name: 'A',
        quantityText: '1',
        unit: 'U' * 21,
        priceText: '1',
      ));
      expect(
        longUnitResult.getLeft().toNullable()?.unitError,
        'Unit must be 20 characters or fewer.',
      );
    });

    test('FR-010 validates price required, format, and <=99999999.99', () {
      // Empty
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: ''))
            .getLeft()
            .toNullable()
            ?.priceError,
        'Enter a price. Use 0 if you do not know it.',
      );

      // Invalid format (more than 2 decimals)
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '10.555'))
            .getLeft()
            .toNullable()
            ?.priceError,
        'Use digits and one dot only, for example 1500.50.',
      );

      // Invalid characters
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '1,500'))
            .getLeft()
            .toNullable()
            ?.priceError,
        'Use digits and one dot only, for example 1500.50.',
      );

      // Price limit
      expect(
        validator(const RawItemInput(name: 'A', quantityText: '1', priceText: '100000000.00'))
            .getLeft()
            .toNullable()
            ?.priceError,
        'Price cannot be more than 99,999,999.99.',
      );

      expect(
        const RawItemInput(name: 'A', quantityText: '1', unit: 'kg', priceText: '10').props,
        ['A', '1', 'kg', '10'],
      );
    });
  });
}
