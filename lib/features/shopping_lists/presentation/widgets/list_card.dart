import 'package:flutter/material.dart';
import 'package:market_list/core/formatting/date_formatter.dart';
import 'package:market_list/core/formatting/money_formatter.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onRename,
    required this.onChangeCurrency,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ListSummary summary;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onChangeCurrency;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countText = summary.itemCount == 1
        ? '1 item'
        : '${summary.itemCount} items';
    final dateText = 'Updated ${DateFormatter.format(summary.list.updatedAt)}';
    final totalText = MoneyFormatter.format(
      summary.total,
      summary.list.currency,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.list.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$countText • $dateText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case 'rename':
                          onRename();
                        case 'currency':
                          onChangeCurrency();
                        case 'duplicate':
                          onDuplicate();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'currency',
                        child: Text('Change currency'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
