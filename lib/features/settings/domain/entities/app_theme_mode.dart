enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromString(String value) {
    return switch (value.toLowerCase()) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}
