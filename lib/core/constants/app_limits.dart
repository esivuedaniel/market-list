class AppLimits {
  const AppLimits._();

  static const int maxLists = 100;
  static const int maxItemsPerList = 500;

  static const int maxItemNameLength = 80;
  static const int maxListNameLength = 60;
  static const int maxUnitLength = 20;

  static const int minQuantityMilli = 1; // 0.001
  static const int maxQuantityMilli = 9999999; // 9,999.999

  static const int minUnitPriceMinor = 0; // 0.00
  static const int maxUnitPriceMinor = 9999999999; // 99,999,999.99

  static const int undoWindowSeconds = 5;
  static const int exportRetentionHours = 24;
}
