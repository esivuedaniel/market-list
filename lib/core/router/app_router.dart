import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/di/injection.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_bloc.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_event.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_cubit.dart';
import 'package:market_list/features/items/presentation/pages/item_form_page.dart';
import 'package:market_list/features/items/presentation/pages/list_detail_page.dart';
import 'package:market_list/features/settings/presentation/pages/settings_page.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/pages/lists_page.dart';

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
          builder: (_) => BlocProvider<ListsCubit>(
            create: (_) => getIt<ListsCubit>()..watch(),
            child: const ListsPage(),
          ),
        );
      case settings:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => const SettingsPage(),
        );
      case listDetail:
        final args = routeSettings.arguments as ListDetailArgs?;
        final listId = args?.listId ?? '';
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => BlocProvider<ListDetailBloc>(
            create: (_) => getIt<ListDetailBloc>()
              ..add(ListDetailStarted(listId)),
            child: const ListDetailPage(),
          ),
        );
      case itemForm:
        final args = routeSettings.arguments as ItemFormArgs? ??
            const ItemFormArgs(listId: '', initialCurrency: 'USD');
        return MaterialPageRoute<ShoppingItem?>(
          settings: routeSettings,
          builder: (_) => BlocProvider<ItemFormCubit>(
            create: (_) => getIt<ItemFormCubit>(param1: args)..load(),
            child: const ItemFormPage(),
          ),
        );
      default:
        return MaterialPageRoute<void>(
          settings: routeSettings,
          builder: (_) => BlocProvider<ListsCubit>(
            create: (_) => getIt<ListsCubit>()..watch(),
            child: const ListsPage(),
          ),
        );
    }
  }
}

