import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

class ShoppingItem extends Equatable {
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.quantity,
    this.unit,
    required this.unitPrice,
    required this.isBought,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String listId;
  final String name;
  final Quantity quantity;
  final String? unit;
  final Money unitPrice;
  final bool isBought;
  final DateTime createdAt;
  final DateTime updatedAt;

  Money get lineTotal => Money.calculateLineTotal(
        quantity: quantity,
        unitPrice: unitPrice,
      );

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    Quantity? quantity,
    String? unit,
    Money? unitPrice,
    bool? isBought,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listId,
        name,
        quantity,
        unit,
        unitPrice,
        isBought,
        createdAt,
        updatedAt,
      ];
}
