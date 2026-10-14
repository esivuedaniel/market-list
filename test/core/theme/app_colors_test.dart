import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/theme/app_colors.dart';

void main() {
  group('G5 AppColors', () {
    test('G5 copyWith updates fields correctly', () {
      const colors = AppColors(
        primaryText: Color(0xFFB45200),
        success: Color(0xFF2E7D32),
      );

      final updated = colors.copyWith(
        primaryText: const Color(0xFFFFB74D),
      );

      expect(updated.primaryText, const Color(0xFFFFB74D));
      expect(updated.success, const Color(0xFF2E7D32));
    });

    test('G5 lerp interpolates colors', () {
      const start = AppColors.light;
      const end = AppColors.dark;

      final mid = start.lerp(end, 0.5);
      expect(mid.primaryText, isNotNull);
      expect(mid.success, isNotNull);

      final self = start.lerp(null, 0.5);
      expect(self, equals(start));
    });
  });
}
