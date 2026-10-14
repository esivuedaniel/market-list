import 'package:equatable/equatable.dart';

class ItemValidationErrors extends Equatable {
  const ItemValidationErrors({
    this.nameError,
    this.quantityError,
    this.unitError,
    this.priceError,
  });

  final String? nameError;
  final String? quantityError;
  final String? unitError;
  final String? priceError;

  bool get hasErrors =>
      nameError != null ||
      quantityError != null ||
      unitError != null ||
      priceError != null;

  @override
  List<Object?> get props => [nameError, quantityError, unitError, priceError];
}
