import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primaryText,
    required this.success,
  });

  final Color primaryText;
  final Color success;

  static const light = AppColors(
    primaryText: Color(0xFFB45200),
    success: Color(0xFF2E7D32),
  );

  static const dark = AppColors(
    primaryText: Color(0xFFFFB74D),
    success: Color(0xFF81C784),
  );

  @override
  AppColors copyWith({
    Color? primaryText,
    Color? success,
  }) {
    return AppColors(
      primaryText: primaryText ?? this.primaryText,
      success: success ?? this.success,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
