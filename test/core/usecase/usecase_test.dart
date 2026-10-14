import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/usecase/usecase.dart';

void main() {
  group('UseCase base tests', () {
    test('NoParams equality and props', () {
      const p1 = NoParams();
      const p2 = NoParams();
      expect(p1, equals(p2));
      expect(p1.props, isEmpty);
    });
  });
}
