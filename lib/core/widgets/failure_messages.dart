import 'package:market_list/core/error/failures.dart';

/// Single source of truth for all user-facing error and failure messages.
///
/// Follows PRD section 12 character for character.
abstract final class FailureMessages {
  // 12.1 Field validation
  static const String enterItemName = 'Enter an item name.';
  static const String itemNameTooLong =
      'Item name must be 80 characters or fewer.';
  static const String enterQuantity = 'Enter a quantity.';
  static const String invalidQuantityFormat =
      'Use digits and one dot only, for example 2.5.';
  static const String quantityMustBePositive =
      'Quantity must be greater than 0.';
  static const String quantityTooLarge =
      'Quantity cannot be more than 9,999.999.';
  static const String unitTooLong = 'Unit must be 20 characters or fewer.';
  static const String enterPrice =
      'Enter a price. Use 0 if you do not know it.';
  static const String invalidPriceFormat =
      'Use digits and one dot only, for example 1500.50.';
  static const String priceTooLarge =
      'Price cannot be more than 99,999,999.99.';
  static const String enterListName = 'Enter a list name.';
  static const String listNameTooLong =
      'List name must be 60 characters or fewer.';

  // 12.2 Limits and system errors
  static const String listItemsLimitReached =
      'This list has 500 items. Remove an item to add another.';
  static const String undoItemsLimitReached =
      'This list already has 500 items. Remove one before you undo.';
  static const String listsLimitReached =
      'You have 100 lists. Delete a list to create another.';
  static const String storageFullSave =
      'Your phone storage is full. Free some space and try again.';
  static const String storageFullPdf =
      'Could not create the PDF. Your phone storage may be full.';
  static const String databaseErrorSave =
      'Something went wrong while saving. Try again.';
  static const String databaseCannotOpen =
      'Could not open your data. Close the app and try again.';
  static const String schemaTooNew =
      'This data was created by a newer version of the app. Update the app to open it.';
  static const String itemLoadFailed = 'Could not load this item.';
  static const String settingSaveFailed = 'Could not save your setting.';
  static const String firstRunSaveFailed =
      'Something went wrong while saving. Try again.';
  static const String pdfBuildFailed = 'Could not create the PDF. Try again.';
  static const String shareSheetFailed =
      'Could not open the share sheet. Try again.';

  // Section 6 screen messages
  static const String couldNotLoadLists = 'Could not load your lists.';
  static const String couldNotLoadList = 'Could not load this list.';
  static const String emptyListShareTooltip =
      'Add at least one item to share.';

  static String noItemsMatch(String query) => 'No items match "$query".';

  /// Maps a [Failure] to its user-facing message.
  static String mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ValidationFailure(:final message) =>
        message ?? 'Please check your input.',
      NotFoundFailure() => itemLoadFailed,
      LimitFailure(:final kind) => switch (kind) {
          LimitKind.lists => listsLimitReached,
          LimitKind.items => listItemsLimitReached,
        },
      StorageFullFailure() => storageFullSave,
      SchemaTooNewFailure() => schemaTooNew,
      DatabaseFailure() => databaseErrorSave,
      ExportFailure() => pdfBuildFailed,
      ShareFailure() => shareSheetFailed,
      UnexpectedFailure() => databaseErrorSave,
    };
  }
}
