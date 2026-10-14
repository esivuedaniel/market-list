import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/core/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('routes generate correctly', () {
      final listsRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.lists),
      );
      expect(listsRoute, isA<MaterialPageRoute<void>>());

      final settingsRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRouter.settings),
      );
      expect(settingsRoute, isA<MaterialPageRoute<void>>());

      final detailRoute = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRouter.listDetail,
          arguments: ListDetailArgs(listId: '123'),
        ),
      );
      expect(detailRoute, isA<MaterialPageRoute<void>>());

      final itemFormRoute = AppRouter.onGenerateRoute(
        const RouteSettings(
          name: AppRouter.itemForm,
          arguments: ItemFormArgs(listId: '123', initialCurrency: 'USD'),
        ),
      );
      expect(itemFormRoute, isA<MaterialPageRoute<void>>());

      final unknownRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/unknown'),
      );
      expect(unknownRoute, isA<MaterialPageRoute<void>>());
    });
  });
}
