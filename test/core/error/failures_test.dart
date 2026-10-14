import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/error/failures.dart';

void main() {
  group('Failure hierarchy tests', () {
    test('PRD-9.6 verify equality and props of all Failure types', () {
      expect(const ValidationFailure('msg'), equals(const ValidationFailure('msg')));
      expect(const ValidationFailure('a'), isNot(equals(const ValidationFailure('b'))));

      expect(const NotFoundFailure(), equals(const NotFoundFailure()));

      expect(const LimitFailure(LimitKind.lists),
          equals(const LimitFailure(LimitKind.lists)));
      expect(const LimitFailure(LimitKind.lists),
          isNot(equals(const LimitFailure(LimitKind.items))));

      expect(const StorageFullFailure(), equals(const StorageFullFailure()));
      expect(const SchemaTooNewFailure(), equals(const SchemaTooNewFailure()));

      expect(const DatabaseFailure('db error').props, ['db error']);
      expect(const ExportFailure('pdf error').props, ['pdf error']);
      expect(const ShareFailure('share error').props, ['share error']);
      expect(const UnexpectedFailure('unexpected').props, ['unexpected']);
      expect(const StorageFullFailure().props, isEmpty);
      expect(const SchemaTooNewFailure().props, isEmpty);
      expect(const NotFoundFailure().props, isEmpty);
    });
  });
}

