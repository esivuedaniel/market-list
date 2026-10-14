import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/domain/text_normalizer.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/entities/item_validation_errors.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';
import 'package:market_list/features/items/domain/usecases/get_item.dart';
import 'package:market_list/features/items/domain/usecases/has_duplicate_item_name.dart';
import 'package:market_list/features/items/domain/usecases/update_item.dart';
import 'package:market_list/features/items/domain/usecases/validate_item_draft.dart';
import 'package:market_list/features/items/presentation/cubit/item_form_state.dart';

class ItemFormCubit extends Cubit<ItemFormState> {
  ItemFormCubit({
    required String listId,
    String? itemId,
    required CurrencyCode initialCurrency,
    required AddItem addItem,
    required UpdateItem updateItem,
    required GetItem getItem,
    required DeleteItem deleteItem,
    required HasDuplicateItemName hasDuplicateItemName,
    required ValidateItemDraft validateItemDraft,
  })  : _listId = listId,
        _itemId = itemId,
        _initialCurrency = initialCurrency,
        _addItem = addItem,
        _updateItem = updateItem,
        _getItem = getItem,
        _deleteItem = deleteItem,
        _hasDuplicateItemName = hasDuplicateItemName,
        _validateItemDraft = validateItemDraft,
        super(
          ItemFormState(
            status: itemId != null ? ItemFormStatus.loading : ItemFormStatus.ready,
            isEdit: itemId != null,
            currency: initialCurrency,
          ),
        );

  final String _listId;
  final String? _itemId;
  final CurrencyCode _initialCurrency;
  final AddItem _addItem;
  final UpdateItem _updateItem;
  final GetItem _getItem;
  final DeleteItem _deleteItem;
  final HasDuplicateItemName _hasDuplicateItemName;
  final ValidateItemDraft _validateItemDraft;

  bool _pendingAddAnother = false;

  Future<void> load() async {
    if (_itemId == null) {
      emit(
        state.copyWith(
          status: ItemFormStatus.ready,
          isEdit: false,
          currency: _initialCurrency,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ItemFormStatus.loading,
        isEdit: true,
        currency: _initialCurrency,
      ),
    );

    final result = await _getItem(_itemId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemFormStatus.failure,
          message: () => FailureMessages.itemLoadFailed,
        ),
      ),
      (item) {
        final qStr = _formatQuantityForInput(item.quantity);
        final pStr = _formatPriceForInput(item.unitPrice);
        final preview = Money.calculateLineTotal(
          quantity: item.quantity,
          unitPrice: item.unitPrice,
        );

        emit(
          state.copyWith(
            status: ItemFormStatus.ready,
            isEdit: true,
            initialItem: () => item,
            name: item.name,
            quantityText: qStr,
            unit: () => item.unit,
            priceText: pStr,
            linePreview: () => preview,
            isDirty: false,
            errors: const ItemValidationErrors(),
          ),
        );
      },
    );
  }

  void nameChanged(String name) {
    _updateField(name: name);
  }

  void quantityChanged(String quantityText) {
    _updateField(quantityText: quantityText);
  }

  void unitChanged(String? unit) {
    _updateField(unit: () => unit);
  }

  void unitChipSelected(String chipUnit) {
    _updateField(unit: () => chipUnit);
  }

  void priceChanged(String priceText) {
    _updateField(priceText: priceText);
  }

  void fieldBlurred(ItemFormField field) {
    final updated = Set<ItemFormField>.from(state.touched)..add(field);
    emit(state.copyWith(touched: updated));
  }

  void _updateField({
    String? name,
    String? quantityText,
    String? Function()? unit,
    String? priceText,
  }) {
    final nextName = name ?? state.name;
    final nextQuantity = quantityText ?? state.quantityText;
    final nextUnit = unit != null ? unit() : state.unit;
    final nextPrice = priceText ?? state.priceText;

    final validationResult = _validateItemDraft(
      RawItemInput(
        name: nextName,
        quantityText: nextQuantity,
        unit: nextUnit,
        priceText: nextPrice,
      ),
    );

    final errors = validationResult.fold(
      (errs) => errs,
      (_) => const ItemValidationErrors(),
    );

    final preview = _calculateLinePreview(nextQuantity, nextPrice);

    final nextStatus = state.status == ItemFormStatus.savedAndReset
        ? ItemFormStatus.ready
        : state.status;

    emit(
      state.copyWith(
        status: nextStatus,
        name: nextName,
        quantityText: nextQuantity,
        unit: () => nextUnit,
        priceText: nextPrice,
        errors: errors,
        linePreview: () => preview,
        isDirty: true,
      ),
    );
  }

  Future<void> submit({bool addAnother = false}) async {
    if (state.status == ItemFormStatus.submitting) return;
    _pendingAddAnother = addAnother;

    final validationResult = _validateItemDraft(
      RawItemInput(
        name: state.name,
        quantityText: state.quantityText,
        unit: state.unit,
        priceText: state.priceText,
      ),
    );

    if (validationResult.isLeft()) {
      final errors = validationResult.getLeft().toNullable()!;
      emit(
        state.copyWith(
          errors: errors,
          showErrors: true,
          status: ItemFormStatus.ready,
        ),
      );
      return;
    }

    final draft = validationResult.getOrElse(
      (_) => throw StateError('Unreachable validation branch'),
    );

    // Duplicate check: add mode, or edit mode when normalized name changed
    final nameChangedInEdit = state.isEdit &&
        TextNormalizer.normalize(draft.name).toLowerCase() !=
            TextNormalizer.normalize(state.initialItem?.name ?? '')
                .toLowerCase();

    if (!state.isEdit || nameChangedInEdit) {
      final dupResult = await _hasDuplicateItemName(
        DuplicateCheckParams(
          listId: _listId,
          name: draft.name,
          excludeItemId: _itemId,
        ),
      );
      if (isClosed) return;

      final isDuplicate = dupResult.getOrElse((_) => false);
      if (isDuplicate) {
        emit(
          state.copyWith(
            status: ItemFormStatus.duplicateWarning,
            showErrors: true,
          ),
        );
        return;
      }
    }

    await _saveDraft(draft, addAnother: addAnother);
  }

  Future<void> confirmDuplicate() async {
    if (state.status != ItemFormStatus.duplicateWarning) return;

    final validationResult = _validateItemDraft(
      RawItemInput(
        name: state.name,
        quantityText: state.quantityText,
        unit: state.unit,
        priceText: state.priceText,
      ),
    );

    if (validationResult.isRight()) {
      final draft = validationResult.getOrElse(
        (_) => throw StateError('Unreachable branch'),
      );
      await _saveDraft(draft, addAnother: _pendingAddAnother);
    }
  }

  void cancelDuplicate() {
    emit(state.copyWith(status: ItemFormStatus.ready));
  }

  Future<void> _saveDraft(ItemDraft draft, {required bool addAnother}) async {
    emit(state.copyWith(status: ItemFormStatus.submitting));

    if (state.isEdit) {
      final result = await _updateItem(
        UpdateItemParams(itemId: _itemId!, draft: draft),
      );
      if (isClosed) return;

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: ItemFormStatus.failure,
            message: () => FailureMessages.mapFailureToMessage(failure),
          ),
        ),
        (updatedItem) => emit(
          state.copyWith(
            status: ItemFormStatus.saved,
            isDirty: false,
          ),
        ),
      );
    } else {
      final result = await _addItem(
        AddItemParams(listId: _listId, draft: draft),
      );
      if (isClosed) return;

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: ItemFormStatus.failure,
            message: () => FailureMessages.mapFailureToMessage(failure),
          ),
        ),
        (createdItem) {
          if (addAnother) {
            emit(
              state.copyWith(
                status: ItemFormStatus.savedAndReset,
                name: '',
                quantityText: '',
                unit: () => null,
                priceText: '',
                errors: const ItemValidationErrors(),
                touched: const {},
                showErrors: false,
                linePreview: () => null,
                isDirty: false,
              ),
            );
          } else {
            emit(
              state.copyWith(
                status: ItemFormStatus.saved,
                isDirty: false,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> delete() async {
    if (!state.isEdit || _itemId == null) return;

    emit(state.copyWith(status: ItemFormStatus.submitting));

    final result = await _deleteItem(_itemId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ItemFormStatus.failure,
          message: () => FailureMessages.mapFailureToMessage(failure),
        ),
      ),
      (deletedItem) => emit(
        state.copyWith(
          status: ItemFormStatus.deleted,
          deletedItem: () => deletedItem,
        ),
      ),
    );
  }

  void messageHandled() {
    emit(state.copyWith(message: () => null));
  }

  static Money? _calculateLinePreview(String quantityText, String priceText) {
    final q = Quantity.tryParse(quantityText);
    final p = Money.tryParse(priceText);
    if (q != null && q.milli > 0 && p != null && p.minor >= 0) {
      return Money.calculateLineTotal(quantity: q, unitPrice: p);
    }
    return null;
  }

  static String _formatQuantityForInput(Quantity quantity) {
    final whole = quantity.milli ~/ 1000;
    final fraction = quantity.milli % 1000;
    if (fraction == 0) return whole.toString();
    final padded =
        fraction.toString().padLeft(3, '0').replaceAll(RegExp(r'0+$'), '');
    return '$whole.$padded';
  }

  static String _formatPriceForInput(Money price) {
    final whole = price.minor ~/ 100;
    final fraction = price.minor % 100;
    if (fraction == 0) return whole.toString();
    final padded =
        fraction.toString().padLeft(2, '0').replaceAll(RegExp(r'0+$'), '');
    return '$whole.$padded';
  }
}
