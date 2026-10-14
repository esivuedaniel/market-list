abstract final class TextNormalizer {

  static final RegExp _whitespaceRun = RegExp(r'\s+');
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');

  /// Normalizes a string per PRD 8.4:
  /// 1. Replace every run of whitespace with one space.
  /// 2. Remove control characters.
  /// 3. Trim both ends.
  static String normalize(String input) {
    final singleSpaced = input.replaceAll(_whitespaceRun, ' ');
    final withoutControls = singleSpaced.replaceAll(_controlChars, '');
    return withoutControls.trim();
  }

  /// Normalizes a unit string per PRD 8.4 rule 4:
  /// An empty result becomes null.
  static String? normalizeUnit(String? input) {
    if (input == null) return null;
    final normalized = normalize(input);
    return normalized.isEmpty ? null : normalized;
  }

  /// Counts characters as Unicode code points (runes.length).
  static int codePointLength(String text) {
    return text.runes.length;
  }
}
