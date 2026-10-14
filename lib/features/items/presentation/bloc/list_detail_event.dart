import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

sealed class ListDetailEvent extends Equatable {
  const ListDetailEvent();

  @override
  List<Object?> get props => [];
}

final class ListDetailStarted extends ListDetailEvent {
  const ListDetailStarted(this.listId);
  final String listId;

  @override
  List<Object?> get props => [listId];
}

final class ListDetailRetried extends ListDetailEvent {
  const ListDetailRetried();
}

final class ItemBoughtToggled extends ListDetailEvent {
  const ItemBoughtToggled({
    required this.itemId,
    required this.isBought,
  });

  final String itemId;
  final bool isBought;

  @override
  List<Object?> get props => [itemId, isBought];
}

final class ItemDeleted extends ListDetailEvent {
  const ItemDeleted(this.itemId);
  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class ItemRestoreRequested extends ListDetailEvent {
  const ItemRestoreRequested(this.item);
  final ShoppingItem item;

  @override
  List<Object?> get props => [item];
}

final class DeletedItemHandled extends ListDetailEvent {
  const DeletedItemHandled();
}

final class SearchQueryChanged extends ListDetailEvent {
  const SearchQueryChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

final class ListRenamed extends ListDetailEvent {
  const ListRenamed(this.name);
  final String name;

  @override
  List<Object?> get props => [name];
}

final class ListCurrencyChanged extends ListDetailEvent {
  const ListCurrencyChanged(this.currency);
  final CurrencyCode currency;

  @override
  List<Object?> get props => [currency];
}

final class ListDeleted extends ListDetailEvent {
  const ListDeleted();
}

final class MessageHandled extends ListDetailEvent {
  const MessageHandled();
}

final class SeedSampleItems extends ListDetailEvent {
  const SeedSampleItems();
}
