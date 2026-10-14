import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class ListDetail extends Equatable {
  const ListDetail({
    required this.list,
    required this.items,
  });

  final ShoppingList list;
  final List<ShoppingItem> items;

  int get itemCount => items.length;

  int get boughtCount => items.where((item) => item.isBought).length;

  Money get total => items.fold<Money>(
        Money.zero,
        (sum, item) => sum + item.lineTotal,
      );

  @override
  List<Object?> get props => [list, items];
}
