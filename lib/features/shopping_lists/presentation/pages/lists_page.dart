import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/router/app_router.dart';
import 'package:market_list/core/widgets/empty_state.dart';
import 'package:market_list/core/widgets/error_view.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_cubit.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/currency_picker_dialog.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/list_card.dart';
import 'package:market_list/features/shopping_lists/presentation/widgets/list_name_dialog.dart';

class ListsPage extends StatelessWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ListsCubit, ListsState>(
      listenWhen: (prev, curr) =>
          curr.message != null || curr.createdListId != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<ListsCubit>().messageHandled();
        }
        if (state.createdListId != null) {
          Navigator.of(context).pushNamed(
            AppRouter.listDetail,
            arguments: ListDetailArgs(listId: state.createdListId!),
          );
          context.read<ListsCubit>().createdListHandled();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Lists'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.settings);
                },
              ),
            ],
          ),
          body: _ListsView(state: state),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('New list'),
          ),
        );
      },
    );
  }
}

class _ListsView extends StatelessWidget {
  const _ListsView({required this.state});

  final ListsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      ListsStatus.loading => const LoadingView(),
      ListsStatus.failure => ErrorView(
          message: state.message ?? FailureMessages.couldNotLoadLists,
          onRetry: () => context.read<ListsCubit>().retry(),
        ),
      ListsStatus.success => state.isEmpty
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'No lists yet',
              buttonText: 'Create your first list',
              onAction: () => _openCreateDialog(context),
            )
          : ListView.builder(
              itemCount: state.lists.length,
              itemBuilder: (context, index) {
                final summary = state.lists[index];
                return ListCard(
                  summary: summary,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.listDetail,
                      arguments: ListDetailArgs(listId: summary.list.id),
                    );
                  },
                  onRename: () => _openRenameDialog(context, summary),
                  onChangeCurrency: () => _openCurrencyDialog(context, summary),
                  onDuplicate: () {
                    context.read<ListsCubit>().duplicateList(summary.list.id);
                  },
                  onDelete: () => _openDeleteDialog(context, summary),
                );
              },
            ),
    };
  }
}

void _openCreateDialog(BuildContext context) {
  showDialog<String>(
    context: context,
    builder: (_) => const ListNameDialog(
      title: 'New list',
      initialName: 'Market list',
      confirmText: 'Create',
    ),
  ).then((name) {
    if (name != null && context.mounted) {
      final defaultCurrency = context
              .read<SettingsCubit>()
              .state
              .settings
              ?.defaultCurrency ??
          CurrencyCode.usd;
      context.read<ListsCubit>().createList(name, defaultCurrency);
    }
  });
}

void _openRenameDialog(BuildContext context, ListSummary summary) {
  showDialog<String>(
    context: context,
    builder: (_) => ListNameDialog(
      title: 'Rename list',
      initialName: summary.list.name,
      confirmText: 'Save',
    ),
  ).then((name) {
    if (name != null && context.mounted) {
      context.read<ListsCubit>().renameList(summary.list.id, name);
    }
  });
}

void _openCurrencyDialog(BuildContext context, ListSummary summary) {
  showDialog<CurrencyCode>(
    context: context,
    builder: (_) => CurrencyPickerDialog(
      currentCurrency: summary.list.currency,
    ),
  ).then((currency) {
    if (currency != null && context.mounted) {
      context.read<ListsCubit>().setCurrency(summary.list.id, currency);
    }
  });
}

void _openDeleteDialog(BuildContext context, ListSummary summary) {
  showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete list'),
      content: Text(
        "Are you sure you want to delete '${summary.list.name}'? This cannot be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true && context.mounted) {
      context.read<ListsCubit>().deleteList(summary.list.id);
    }
  });
}
