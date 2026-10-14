import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/item_validation_errors.dart';

class RawItemInput extends Equatable {
  const RawItemInput({
    required this.name,
    required this.quantityText,
    this.unit,
    required this.priceText,
  });

  final String name;
  final String quantityText;
  final String? unit;
  final String priceText;

  @override
  List<Object?> get props => [name, quantityText, unit, priceText];
}

class ValidateItemDraft {
  const ValidateItemDraft();

  Either<ItemValidationErrors, ItemDraft> call(RawItemInput input) {
    String? nameError;
    String? quantityError;
    String? unitError;
    String? priceError;

    // 1. Item Name
    final normName = TextNormalizer.normalize(input.name);
    if (normName.isEmpty) {
      nameError = 'Enter an item name.';
    } else if (TextNormalizer.codePointLength(normName) >
        AppLimits.maxItemNameLength) {
      nameError = 'Item name must be 80 characters or fewer.';
    }

    // 2. Quantity
    final qTrimmed = input.quantityText.trim();
    Quantity? parsedQuantity;
    if (qTrimmed.isEmpty) {
      quantityError = 'Enter a quantity.';
    } else {
      parsedQuantity = Quantity.tryParse(qTrimmed);
      if (parsedQuantity == null) {
        quantityError = 'Use digits and one dot only, for example 2.5.';
      } else if (parsedQuantity.milli <= 0) {
        quantityError = 'Quantity must be greater than 0.';
      } else if (parsedQuantity.milli > AppLimits.maxQuantityMilli) {
        quantityError = 'Quantity cannot be more than 9,999.999.';
      }
    }

    // 3. Unit
    final normUnit = TextNormalizer.normalizeUnit(input.unit);
    if (normUnit != null &&
        TextNormalizer.codePointLength(normUnit) > AppLimits.maxUnitLength) {
      unitError = 'Unit must be 20 characters or fewer.';
    }

    // 4. Unit Price
    final pTrimmed = input.priceText.trim();
    Money? parsedPrice;
    if (pTrimmed.isEmpty) {
      priceError = 'Enter a price. Use 0 if you do not know it.';
    } else {
      parsedPrice = Money.tryParse(pTrimmed);
      if (parsedPrice == null) {
        priceError = 'Use digits and one dot only, for example 1500.50.';
      } else if (parsedPrice.minor < 0) {
        priceError = 'Enter a price. Use 0 if you do not know it.';
      } else if (parsedPrice.minor > AppLimits.maxUnitPriceMinor) {
        priceError = 'Price cannot be more than 99,999,999.99.';
      }
    }

    final errors = ItemValidationErrors(
      nameError: nameError,
      quantityError: quantityError,
      unitError: unitError,
      priceError: priceError,
    );

    if (errors.hasErrors) {
      return Left(errors);
    }

    return Right(
      ItemDraft(
        name: normName,
        quantity: parsedQuantity!,
        unit: normUnit,
        unitPrice: parsedPrice!,
      ),
    );
  }
}
