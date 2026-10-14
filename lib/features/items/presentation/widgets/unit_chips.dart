import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  const DecimalTextInputFormatter({required this.decimalDigits});

  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final regex = RegExp('^[0-9]*\\.?[0-9]{0,$decimalDigits}\$');
    if (regex.hasMatch(text)) {
      return newValue;
    }

    return oldValue;
  }
}

class UnitChips extends StatelessWidget {
  const UnitChips({
    super.key,
    required this.selectedUnit,
    required this.onSelected,
  });

  static const List<String> units = [
    'kg',
    'g',
    'pcs',
    'bag',
    'bunch',
    'litre',
    'crate',
  ];

  final String? selectedUnit;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: units.map((unit) {
        final isSelected = selectedUnit == unit;
        return ActionChip(
          label: Text(unit),
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                )
              : null,
          onPressed: () => onSelected(unit),
        );
      }).toList(growable: false),
    );
  }
}
