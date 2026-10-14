import 'package:flutter/material.dart';
import 'package:market_list/features/settings/presentation/pages/settings_page.dart';

class ListDetailArgs {
  const ListDetailArgs({required this.listId});
  final String listId;
}

class ItemFormArgs {
  const ItemFormArgs({
    required this.listId,
    this.itemId,
    required this.initialCurrency,
  });

  final String listId;
  final String? itemId;
  final String initialCurrency;
}

class AppRouter {
  const AppRouter._();

  static const String lists = '/';
  static const String settings = '/settings';
  static const String listDetail = '/list';
  static const String itemForm = '/item-form';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case lists:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const _PlaceholderScreen(title: 'Market List'),
        );
      case settings:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const SettingsPage(),
        );
      case listDetail:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const _PlaceholderScreen(title: 'List Detail'),
        );
      case itemForm:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const _PlaceholderScreen(title: 'Item Form'),
        );
      default:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const _PlaceholderScreen(title: 'Market List'),
        );
    }
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Center(
        child: Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
