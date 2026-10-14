import 'package:flutter/material.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/core/theme/app_theme.dart';

class MarketListApp extends StatelessWidget {
  const MarketListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market List',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.lists,
    );
  }
}
