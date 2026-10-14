import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/constants/app_limits.dart';
import 'package:market_list/core/formatting/money_formatter.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/core/widgets/loading_view.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_cubit.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_state.dart';
import 'package:market_list/features/items/presentation/widgets/unit_chips.dart';

class ItemFormPage extends StatefulWidget {
  const ItemFormPage({super.key});

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _unitFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _addBlur(_nameFocus, ItemFormField.name);
    _addBlur(_quantityFocus, ItemFormField.quantity);
    _addBlur(_unitFocus, ItemFormField.unit);
    _addBlur(_priceFocus, ItemFormField.price);
  }

  void _addBlur(FocusNode node, ItemFormField field) {
    node.addListener(() {
      if (!node.hasFocus) {
        context.read<ItemFormCubit>().fieldBlurred(field);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _unitFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _syncControllers(ItemFormState state) {
    if (_nameController.text != state.name) {
      _nameController.text = state.name;
    }
    if (_quantityController.text != state.quantityText) {
      _quantityController.text = state.quantityText;
    }
    if (_unitController.text != (state.unit ?? '')) {
      _unitController.text = state.unit ?? '';
    }
    if (_priceController.text != state.priceText) {
      _priceController.text = state.priceText;
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status || curr.message != null,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
          context.read<ItemFormCubit>().messageHandled();
        }

        if (state.status == ItemFormStatus.saved) {
          Navigator.of(context).pop();
        } else if (state.status == ItemFormStatus.savedAndReset) {
          _syncControllers(state);
          _nameFocus.requestFocus();
        } else if (state.status == ItemFormStatus.deleted) {
          Navigator.of(context).pop(state.deletedItem);
        } else if (state.status == ItemFormStatus.duplicateWarning) {
          _showDuplicateDialog(context, state.name);
        } else if (prevStatusWasLoading(state)) {
          _syncControllers(state);
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.isDirty,
          onPopInvokedWithResult: (didPop, dynamic result) async {
            if (didPop) return;
            final canPop = await _handlePop(context, state.isDirty);
            if (canPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(state.isEdit ? 'Edit item' : 'Add item'),
            ),
            body: state.status == ItemFormStatus.loading
                ? const LoadingView()
                : state.status == ItemFormStatus.failure && state.isEdit && state.initialItem == null
                    ? const _ItemFormErrorView()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ItemFormFields(
                              state: state,
                              nameController: _nameController,
                              quantityController: _quantityController,
                              unitController: _unitController,
                              priceController: _priceController,
                              nameFocus: _nameFocus,
                              quantityFocus: _quantityFocus,
                              unitFocus: _unitFocus,
                              priceFocus: _priceFocus,
                            ),
                            const SizedBox(height: 24),
                            _ItemFormActionButtons(
                              state: state,
                              onCancel: () async {
                                final canPop = await _handlePop(context, state.isDirty);
                                if (canPop && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
          ),
        );
      },
    );
  }

  bool prevStatusWasLoading(ItemFormState state) {
    return state.isEdit &&
        state.status == ItemFormStatus.ready &&
        _nameController.text.isEmpty &&
        state.name.isNotEmpty;
  }
}

class _ItemFormFields extends StatelessWidget {
  const _ItemFormFields({
    required this.state,
    required this.nameController,
    required this.quantityController,
    required this.unitController,
    required this.priceController,
    required this.nameFocus,
    required this.quantityFocus,
    required this.unitFocus,
    required this.priceFocus,
  });

  final ItemFormState state;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController priceController;
  final FocusNode nameFocus;
  final FocusNode quantityFocus;
  final FocusNode unitFocus;
  final FocusNode priceFocus;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('item_form_name_field'),
          controller: nameController,
          focusNode: nameFocus,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          maxLength: AppLimits.maxItemNameLength,
          decoration: InputDecoration(
            labelText: 'Item name *',
            errorText: state.nameError,
          ),
          onChanged: cubit.nameChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('item_form_quantity_field'),
          controller: quantityController,
          focusNode: quantityFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: const [
            DecimalTextInputFormatter(decimalDigits: 3),
          ],
          decoration: InputDecoration(
            labelText: 'Quantity *',
            hintText: 'e.g. 2.5',
            errorText: state.quantityError,
          ),
          onChanged: cubit.quantityChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('item_form_unit_field'),
          controller: unitController,
          focusNode: unitFocus,
          textInputAction: TextInputAction.next,
          maxLength: AppLimits.maxUnitLength,
          decoration: InputDecoration(
            labelText: 'Unit (optional)',
            hintText: 'e.g. kg, pcs, bag',
            errorText: state.unitError,
          ),
          onChanged: cubit.unitChanged,
        ),
        const SizedBox(height: 4),
        UnitChips(
          selectedUnit: state.unit,
          onSelected: (chipUnit) {
            unitController.text = chipUnit;
            cubit.unitChipSelected(chipUnit);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('item_form_price_field'),
          controller: priceController,
          focusNode: priceFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: const [
            DecimalTextInputFormatter(decimalDigits: 2),
          ],
          decoration: InputDecoration(
            labelText: 'Unit price *',
            prefixText: '${state.currency.symbol} ',
            hintText: '0.00',
            errorText: state.priceError,
          ),
          onChanged: cubit.priceChanged,
          onFieldSubmitted: (_) => cubit.submit(),
        ),
        const SizedBox(height: 8),
        if (state.linePreview != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Line total: ${MoneyFormatter.format(state.linePreview!, state.currency)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
      ],
    );
  }
}

class _ItemFormActionButtons extends StatelessWidget {
  const _ItemFormActionButtons({
    required this.state,
    required this.onCancel,
  });

  final ItemFormState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ItemFormCubit>();
    final isSubmitting = state.status == ItemFormStatus.submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('item_form_save_button'),
          onPressed: isSubmitting ? null : () => cubit.submit(),
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
        if (!state.isEdit) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('item_form_save_add_another_button'),
            onPressed:
                isSubmitting ? null : () => cubit.submit(addAnother: true),
            child: const Text('Save and add another'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          key: const Key('item_form_cancel_button'),
          onPressed: isSubmitting ? null : onCancel,
          child: const Text('Cancel'),
        ),
        if (state.isEdit) ...[
          const SizedBox(height: 16),
          TextButton(
            key: const Key('item_form_delete_button'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: isSubmitting ? null : () => cubit.delete(),
            child: const Text('Delete item'),
          ),
        ],
      ],
    );
  }
}

class _ItemFormErrorView extends StatelessWidget {
  const _ItemFormErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            FailureMessages.itemLoadFailed,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }
}

Future<bool> _handlePop(BuildContext context, bool isDirty) async {
  if (!isDirty) return true;

  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text(
        'You have unsaved changes. Are you sure you want to discard them?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return shouldDiscard ?? false;
}

void _showDuplicateDialog(BuildContext context, String name) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Duplicate item'),
      content: Text('$name is already on this list. Add it again?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            context.read<ItemFormCubit>().cancelDuplicate();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            context.read<ItemFormCubit>().confirmDuplicate();
          },
          child: const Text('Add anyway'),
        ),
      ],
    ),
  );
}
