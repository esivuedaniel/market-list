import 'package:flutter/material.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';

class CurrencyPickerDialog extends StatelessWidget {
  const CurrencyPickerDialog({
    super.key,
    required this.currentCurrency,
    this.title = 'Change currency',
  });

  final CurrencyCode currentCurrency;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: RadioGroup<CurrencyCode>(
          groupValue: currentCurrency,
          onChanged: (selected) {
            if (selected != null) {
              Navigator.of(context).pop(selected);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: CurrencyCode.values.map((code) {
              return RadioListTile<CurrencyCode>(
                value: code,
                title: Text('${code.symbol}  ${code.code}'),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
