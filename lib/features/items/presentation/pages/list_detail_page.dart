import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/core/widgets/empty_state.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/items/domain/entities/shopping_item.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_bloc.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_event.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_state.dart';
import 'package:market_list/features/items/presentation/widgets/item_tile.dart';
import 'package:market_list/features/items/presentation/widgets/summary_card.dart';
import 'package:market_list/features/export/presentation/widgets/share_sheet.dart';

enum _ListMenuAction { rename, currency, delete, seed }

class ListDetailPage extends StatefulWidget {
  const ListDetailPage({super.key});

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ListDetailBloc>();

    return PopScope(
      onPopInvokedWithResult: (didPop, dynamic result) {
        bloc.add(const DeletedItemHandled());
      },
      child: BlocConsumer<ListDetailBloc, ListDetailState>(
        listenWhen: (prev, curr) =>
            curr.message != null ||
            curr.deletedItem != null ||
            curr.listRemoved,
        listener: (context, state) {
          if (state.listRemoved) {
            Navigator.of(context).pop();
            return;
          }
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
            bloc.add(const MessageHandled());
          }
          if (state.deletedItem != null) {
            final item = state.deletedItem!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Item deleted'),
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    bloc.add(ItemRestoreRequested(item));
                  },
                ),
              ),
            ).closed.then((_) {
              if (mounted) {
                bloc.add(const DeletedItemHandled());
              }
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: _ListDetailAppBar(
              state: state,
              onRename: () => _showRenameDialog(
                context,
                state.detail?.list.name ?? '',
              ),
              onCurrency: () => _showCurrencyDialog(
                context,
                state.detail?.list.currency ?? CurrencyCode.usd,
              ),
              onDelete: () => _showDeleteDialog(context),
            ),
            body: _ListDetailBody(state: state),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
              onPressed: () => _onAddItemPressed(context, state),
            ),
          );
        },
      ),
    );
  }

  void _onAddItemPressed(BuildContext context, ListDetailState state) {
    final bloc = context.read<ListDetailBloc>();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    bloc.add(const DeletedItemHandled());

    if (state.itemCount >= AppLimits.maxItemsPerList) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(FailureMessages.listItemsLimitReached)),
      );
      return;
    }

    final listId = state.detail?.list.id;
    if (listId == null) return;

    Navigator.of(context).pushNamed(
      AppRouter.itemForm,
      arguments: ItemFormArgs(
        listId: listId,
        initialCurrency: state.detail!.list.currency.code,
      ),
    ).then((result) {
      if (result is ShoppingItem) {
        bloc.add(ItemRestoreRequested(result));
      }
    });
  }
}

class _ListDetailAppBar extends StatefulWidget implements PreferredSizeWidget {
  const _ListDetailAppBar({
    required this.state,
    required this.onRename,
    required this.onCurrency,
    required this.onDelete,
  });

  final ListDetailState state;
  final VoidCallback onRename;
  final VoidCallback onCurrency;
  final VoidCallback onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<_ListDetailAppBar> createState() => _ListDetailAppBarState();
}

class _ListDetailAppBarState extends State<_ListDetailAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearch(BuildContext context) {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    context.read<ListDetailBloc>().add(const SearchQueryChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ListDetailBloc>();
    final state = widget.state;

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search items...',
                border: InputBorder.none,
              ),
              onChanged: (val) {
                bloc.add(SearchQueryChanged(val));
              },
            )
          : Text(state.detail?.list.name ?? 'List Detail'),
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close search',
            onPressed: () => _stopSearch(context),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              setState(() => _isSearching = true);
            },
          ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: state.canShare
              ? 'Share list'
              : FailureMessages.emptyListShareTooltip,
          onPressed: state.canShare
              ? () {
                  ShareBottomSheet.show(context, state.detail!.list.id);
                }
              : null,
        ),
        PopupMenuButton<_ListMenuAction>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'List options',
          onSelected: (action) {
            switch (action) {
              case _ListMenuAction.rename:
                widget.onRename();
              case _ListMenuAction.currency:
                widget.onCurrency();
              case _ListMenuAction.delete:
                widget.onDelete();
              case _ListMenuAction.seed:
                bloc.add(const SeedSampleItems());
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _ListMenuAction.rename,
              child: Text('Rename list'),
            ),
            const PopupMenuItem(
              value: _ListMenuAction.currency,
              child: Text('Change currency'),
            ),
            const PopupMenuItem(
              value: _ListMenuAction.delete,
              child: Text('Delete list'),
            ),
            if (kDebugMode)
              const PopupMenuItem(
                value: _ListMenuAction.seed,
                child: Text('Seed 5 items (debug)'),
              ),
          ],
        ),
      ],
    );
  }
}

class _ListDetailBody extends StatelessWidget {
  const _ListDetailBody({required this.state});

  final ListDetailState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ListDetailStatus.loading => const LoadingView(),
      ListDetailStatus.failure => ErrorView(
          message: state.message ?? FailureMessages.couldNotLoadList,
          onRetry: () {
            context.read<ListDetailBloc>().add(const ListDetailRetried());
          },
        ),
      ListDetailStatus.success => _ListDetailSuccessView(state: state),
    };
  }
}

class _ListDetailSuccessView extends StatelessWidget {
  const _ListDetailSuccessView({required this.state});

  final ListDetailState state;

  @override
  Widget build(BuildContext context) {
    final currency = state.detail?.list.currency ?? CurrencyCode.usd;
    final visibleItems = state.visibleItems;
    final bloc = context.read<ListDetailBloc>();

    return Column(
      children: [
        SummaryCard(
          total: state.total,
          currency: currency,
          boughtCount: state.boughtCount,
          itemCount: state.itemCount,
        ),
        Expanded(
          child: state.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: 'No items yet. Tap Add item to start.',
                )
              : visibleItems.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: FailureMessages.noItemsMatch(state.query),
                    )
                  : ListView.builder(
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return ItemTile(
                          item: item,
                          currency: currency,
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            bloc.add(const DeletedItemHandled());
                            Navigator.of(context).pushNamed(
                              AppRouter.itemForm,
                              arguments: ItemFormArgs(
                                listId: state.detail!.list.id,
                                itemId: item.id,
                                initialCurrency: currency.code,
                              ),
                            ).then((result) {
                              if (result is ShoppingItem) {
                                bloc.add(ItemRestoreRequested(result));
                              }
                            });
                          },
                          onBoughtToggled: (isBought) {
                            bloc.add(
                              ItemBoughtToggled(
                                itemId: item.id,
                                isBought: isBought,
                              ),
                            );
                          },
                          onDelete: () {
                            bloc.add(ItemDeleted(item.id));
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

void _showRenameDialog(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  final formKey = GlobalKey<FormState>();

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Rename list'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: AppLimits.maxListNameLength,
          decoration: const InputDecoration(labelText: 'List name'),
          validator: (value) {
            final normalized = TextNormalizer.normalize(value ?? '');
            if (normalized.isEmpty) {
              return FailureMessages.enterListName;
            }
            if (normalized.runes.length > AppLimits.maxListNameLength) {
              return FailureMessages.listNameTooLong;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final newName = TextNormalizer.normalize(controller.text);
              context.read<ListDetailBloc>().add(ListRenamed(newName));
              Navigator.of(dialogCtx).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showCurrencyDialog(BuildContext context, CurrencyCode current) {
  CurrencyCode selected = current;

  showDialog<void>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Change currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prices are not converted.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              RadioGroup<CurrencyCode>(
                groupValue: selected,
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selected = val);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: CurrencyCode.values
                      .map(
                        (code) => RadioListTile<CurrencyCode>(
                          title: Text('${code.symbol} (${code.code})'),
                          value: code,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ListDetailBloc>().add(ListCurrencyChanged(selected));
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Delete list?'),
      content: const Text('This will delete the list and all its items permanently.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () {
            context.read<ListDetailBloc>().add(const ListDeleted());
            Navigator.of(dialogCtx).pop();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
