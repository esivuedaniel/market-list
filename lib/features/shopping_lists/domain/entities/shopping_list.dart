import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';

class ShoppingList extends Equatable {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final CurrencyCode currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList copyWith({
    String? id,
    String? name,
    CurrencyCode? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, currency, createdAt, updatedAt];
}
