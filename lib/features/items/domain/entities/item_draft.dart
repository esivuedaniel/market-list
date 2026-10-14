import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';

class ItemDraft extends Equatable {
  const ItemDraft({
    required this.name,
    required this.quantity,
    this.unit,
    required this.unitPrice,
  });

  final String name;
  final Quantity quantity;
  final String? unit;
  final Money unitPrice;

  ItemDraft copyWith({
    String? name,
    Quantity? quantity,
    String? unit,
    Money? unitPrice,
  }) {
    return ItemDraft(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  List<Object?> get props => [name, quantity, unit, unitPrice];
}
