import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/items/domain/entities/list_detail.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

enum ListDetailStatus { loading, success, failure }

class ListDetailState extends Equatable {
  const ListDetailState({
    this.status = ListDetailStatus.loading,
    this.detail,
    this.query = '',
    this.deletedItem,
    this.message,
    this.listRemoved = false,
  });

  final ListDetailStatus status;
  final ListDetail? detail;
  final String query;
  final ShoppingItem? deletedItem;
  final String? message;
  final bool listRemoved;

  List<ShoppingItem> get visibleItems {
    final items = detail?.items ?? const <ShoppingItem>[];
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return items;
    }
    return items
        .where((item) => item.name.toLowerCase().contains(trimmedQuery))
        .toList(growable: false);
  }

  Money get total => detail?.total ?? Money.zero;

  int get boughtCount => detail?.boughtCount ?? 0;

  int get itemCount => detail?.itemCount ?? 0;

  bool get isEmpty =>
      status == ListDetailStatus.success && (detail?.items.isEmpty ?? true);

  bool get canShare =>
      status == ListDetailStatus.success && (detail?.items.isNotEmpty ?? false);

  ListDetailState copyWith({
    ListDetailStatus? status,
    ListDetail? detail,
    String? query,
    ShoppingItem? deletedItem,
    bool clearDeletedItem = false,
    String? message,
    bool clearMessage = false,
    bool? listRemoved,
  }) {
    return ListDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      query: query ?? this.query,
      deletedItem:
          clearDeletedItem ? null : (deletedItem ?? this.deletedItem),
      message: clearMessage ? null : (message ?? this.message),
      listRemoved: listRemoved ?? this.listRemoved,
    );
  }

  @override
  List<Object?> get props => [
        status,
        detail,
        query,
        deletedItem,
        message,
        listRemoved,
      ];
}
