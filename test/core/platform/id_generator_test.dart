import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/platform/id_generator.dart';

void main() {
  group('IdGenerator tests', () {
    test('FR-080 generates valid non-empty UUID v4 strings', () {
      const generator = IdGenerator();
      final id1 = generator.generate();
      final id2 = generator.generate();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));

      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidV4Regex.hasMatch(id1), isTrue);
      expect(uuidV4Regex.hasMatch(id2), isTrue);
    });
  });
}
