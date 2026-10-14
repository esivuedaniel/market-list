import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/shopping_lists/domain/entities/shopping_list.dart';

class ListSummary extends Equatable {
  const ListSummary({
    required this.list,
    required this.itemCount,
    required this.total,
  });

  final ShoppingList list;
  final int itemCount;
  final Money total;

  @override
  List<Object?> get props => [list, itemCount, total];
}
