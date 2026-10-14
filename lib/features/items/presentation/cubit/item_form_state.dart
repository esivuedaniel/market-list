import 'package:equatable/equatable.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/features/items/domain/entities/item_validation_errors.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

enum ItemFormStatus {
  loading,
  ready,
  submitting,
  duplicateWarning,
  saved,
  savedAndReset,
  deleted,
  failure,
}

enum ItemFormField {
  name,
  quantity,
  unit,
  price,
}

class ItemFormState extends Equatable {
  const ItemFormState({
    this.status = ItemFormStatus.ready,
    this.isEdit = false,
    this.name = '',
    this.quantityText = '',
    this.unit,
    this.priceText = '',
    this.currency = CurrencyCode.usd,
    this.errors = const ItemValidationErrors(),
    this.touched = const <ItemFormField>{},
    this.showErrors = false,
    this.linePreview,
    this.isDirty = false,
    this.message,
    this.deletedItem,
    this.initialItem,
  });

  final ItemFormStatus status;
  final bool isEdit;
  final String name;
  final String quantityText;
  final String? unit;
  final String priceText;
  final CurrencyCode currency;
  final ItemValidationErrors errors;
  final Set<ItemFormField> touched;
  final bool showErrors;
  final Money? linePreview;
  final bool isDirty;
  final String? message;
  final ShoppingItem? deletedItem;
  final ShoppingItem? initialItem;

  bool showErrorFor(ItemFormField field) {
    return showErrors || touched.contains(field);
  }

  String? get nameError =>
      showErrorFor(ItemFormField.name) ? errors.nameError : null;

  String? get quantityError =>
      showErrorFor(ItemFormField.quantity) ? errors.quantityError : null;

  String? get unitError =>
      showErrorFor(ItemFormField.unit) ? errors.unitError : null;

  String? get priceError =>
      showErrorFor(ItemFormField.price) ? errors.priceError : null;

  ItemFormState copyWith({
    ItemFormStatus? status,
    bool? isEdit,
    String? name,
    String? quantityText,
    String? Function()? unit,
    String? priceText,
    CurrencyCode? currency,
    ItemValidationErrors? errors,
    Set<ItemFormField>? touched,
    bool? showErrors,
    Money? Function()? linePreview,
    bool? isDirty,
    String? Function()? message,
    ShoppingItem? Function()? deletedItem,
    ShoppingItem? Function()? initialItem,
  }) {
    return ItemFormState(
      status: status ?? this.status,
      isEdit: isEdit ?? this.isEdit,
      name: name ?? this.name,
      quantityText: quantityText ?? this.quantityText,
      unit: unit != null ? unit() : this.unit,
      priceText: priceText ?? this.priceText,
      currency: currency ?? this.currency,
      errors: errors ?? this.errors,
      touched: touched ?? this.touched,
      showErrors: showErrors ?? this.showErrors,
      linePreview: linePreview != null ? linePreview() : this.linePreview,
      isDirty: isDirty ?? this.isDirty,
      message: message != null ? message() : this.message,
      deletedItem: deletedItem != null ? deletedItem() : this.deletedItem,
      initialItem: initialItem != null ? initialItem() : this.initialItem,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isEdit,
        name,
        quantityText,
        unit,
        priceText,
        currency,
        errors,
        touched,
        showErrors,
        linePreview,
        isDirty,
        message,
        deletedItem,
        initialItem,
      ];
}
