import 'package:flutter/material.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/formatting/money_formatter.dart';
import 'package:market_list/core/formatting/quantity_formatter.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';

enum ItemAction { edit, delete }

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onBoughtToggled,
    required this.onDelete,
  });

  final ShoppingItem item;
  final CurrencyCode currency;
  final VoidCallback onTap;
  final ValueChanged<bool> onBoughtToggled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBought = item.isBought;

    final qtyStr = QuantityFormatter.format(item.quantity);
    final unitPart = item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : '';
    final formattedPrice = MoneyFormatter.format(item.unitPrice, currency);
    final subtitleText = '$qtyStr$unitPart x $formattedPrice';
    final lineTotalText = MoneyFormatter.format(item.lineTotal, currency);

    final statusText = isBought ? 'bought' : 'not bought';
    final semanticsLabel =
        '${item.name}, $qtyStr$unitPart, $formattedPrice each, total $lineTotalText, $statusText';

    final textDecoration = isBought ? TextDecoration.lineThrough : null;
    final textColor = isBought ? colorScheme.onSurfaceVariant : colorScheme.onSurface;

    return Dismissible(
      key: ValueKey('dismissible-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Semantics(
        label: semanticsLabel,
        container: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Checkbox(
                  value: isBought,
                  onChanged: (val) {
                    if (val != null) {
                      onBoughtToggled(val);
                    }
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: textDecoration,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          decoration: textDecoration,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lineTotalText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    decoration: textDecoration,
                    color: textColor,
                  ),
                ),
                PopupMenuButton<ItemAction>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Item options',
                  onSelected: (action) {
                    switch (action) {
                      case ItemAction.edit:
                        onTap();
                      case ItemAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: ItemAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: ItemAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
