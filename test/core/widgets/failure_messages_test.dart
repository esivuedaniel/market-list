import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';

void main() {
  group('FailureMessages', () {
    test('maps ValidationFailure with custom message', () {
      expect(
        FailureMessages.mapFailureToMessage(
          const ValidationFailure('Custom message'),
        ),
        'Custom message',
      );
    });

    test('maps ValidationFailure without message to default', () {
      expect(
        FailureMessages.mapFailureToMessage(const ValidationFailure()),
        'Please check your input.',
      );
    });

    test('maps NotFoundFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const NotFoundFailure()),
        'Could not load this item.',
      );
    });

    test('maps LimitFailure for lists and items', () {
      expect(
        FailureMessages.mapFailureToMessage(
          const LimitFailure(LimitKind.lists),
        ),
        'You have 100 lists. Delete a list to create another.',
      );
      expect(
        FailureMessages.mapFailureToMessage(
          const LimitFailure(LimitKind.items),
        ),
        'This list has 500 items. Remove an item to add another.',
      );
    });

    test('maps StorageFullFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const StorageFullFailure()),
        'Your phone storage is full. Free some space and try again.',
      );
    });

    test('maps SchemaTooNewFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const SchemaTooNewFailure()),
        'This data was created by a newer version of the app. Update the app to open it.',
      );
    });

    test('maps DatabaseFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const DatabaseFailure()),
        'Something went wrong while saving. Try again.',
      );
    });

    test('maps ExportFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const ExportFailure()),
        'Could not create the PDF. Try again.',
      );
    });

    test('maps ShareFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const ShareFailure()),
        'Could not open the share sheet. Try again.',
      );
    });

    test('maps UnexpectedFailure', () {
      expect(
        FailureMessages.mapFailureToMessage(const UnexpectedFailure()),
        'Something went wrong while saving. Try again.',
      );
    });

    test('formats noItemsMatch correctly', () {
      expect(FailureMessages.noItemsMatch('apple'), 'No items match "apple".');
    });
  });
}
