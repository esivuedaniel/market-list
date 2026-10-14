import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/constants/app_limits.dart';

void main() {
  group('AS-09 AppLimits constants', () {
    test('AS-09 verify maximum and minimum bounds', () {
      expect(AppLimits.maxLists, 100);
      expect(AppLimits.maxItemsPerList, 500);
      expect(AppLimits.maxItemNameLength, 80);
      expect(AppLimits.maxListNameLength, 60);
      expect(AppLimits.maxUnitLength, 20);
      expect(AppLimits.minQuantityMilli, 1);
      expect(AppLimits.maxQuantityMilli, 9999999);
      expect(AppLimits.minUnitPriceMinor, 0);
      expect(AppLimits.maxUnitPriceMinor, 9999999999);
      expect(AppLimits.undoWindowSeconds, 5);
      expect(AppLimits.exportRetentionHours, 24);
    });
  });
}
