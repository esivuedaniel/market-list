import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/domain/text_normalizer.dart';

void main() {
  group('TextNormalizer tests', () {
    test(
        'FR-011/FR-002 normalizes whitespace runs, removes control chars, trims ends',
        () {
      // 1. Whitespace runs: tabs, newlines, multiple spaces
      const input = "  Fresh \t\t red \n\n apples   ";
      final result = TextNormalizer.normalize(input);
      expect(result, "Fresh red apples");

      // 2. Control characters removed
      const withControls = "Milk\x00\x07\x1F\x7Fcarton";
      final resultControls = TextNormalizer.normalize(withControls);
      expect(resultControls, "Milkcarton");

      // 3. Leading and trailing whitespace trimmed
      const untrimmed = "   Bread   ";
      expect(TextNormalizer.normalize(untrimmed), "Bread");
    });

    test('FR-013 normalizeUnit converts empty result to null', () {
      expect(TextNormalizer.normalizeUnit('   '), isNull);
      expect(TextNormalizer.normalizeUnit('\t\n'), isNull);
      expect(TextNormalizer.normalizeUnit(''), isNull);
      expect(TextNormalizer.normalizeUnit(null), isNull);
      expect(TextNormalizer.normalizeUnit('  kg  '), 'kg');
    });

    test('AS-09 codePointLength counts Unicode code points via runes.length', () {
      // Standard ASCII
      expect(TextNormalizer.codePointLength('Apple'), 5);

      // Emoji with surrogate pair (2 UTF-16 code units, 1 code point)
      const emoji = '🍎';
      expect(emoji.length, 2); // String.length is 2
      expect(TextNormalizer.codePointLength(emoji), 1); // code point length is 1

      const textWithEmojis = 'Milk 🥛 and bread 🍞';
      expect(TextNormalizer.codePointLength(textWithEmojis), 18);
    });
  });
}
