import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_list/core/domain/value_objects/money.dart';
import 'package:market_list/core/domain/value_objects/quantity.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/items/domain/entities/item_draft.dart';
import 'package:market_list/features/items/domain/usecases/add_item.dart';
import 'package:market_list/features/items/domain/usecases/delete_item.dart';
import 'package:market_list/features/items/domain/usecases/restore_item.dart';
import 'package:market_list/features/items/domain/usecases/set_item_bought.dart';
import 'package:market_list/features/items/domain/usecases/watch_list_detail.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_event.dart';
import 'package:market_list/features/items/presentation/bloc/list_detail_state.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';

class ListDetailBloc extends Bloc<ListDetailEvent, ListDetailState> {
  ListDetailBloc({
    required WatchListDetail watchListDetail,
    required SetItemBought setItemBought,
    required DeleteItem deleteItem,
    required RestoreItem restoreItem,
    required RenameList renameList,
    required SetListCurrency setListCurrency,
    required DeleteList deleteList,
    required AddItem addItem,
  })  : _watchListDetail = watchListDetail,
        _setItemBought = setItemBought,
        _deleteItem = deleteItem,
        _restoreItem = restoreItem,
        _renameList = renameList,
        _setListCurrency = setListCurrency,
        _deleteList = deleteList,
        _addItem = addItem,
        super(const ListDetailState()) {
    on<ListDetailStarted>(_onStarted, transformer: restartable());
    on<ListDetailRetried>(_onRetried, transformer: restartable());
    on<ItemBoughtToggled>(_onItemBoughtToggled);
    on<ItemDeleted>(_onItemDeleted);
    on<ItemRestoreRequested>(_onItemRestoreRequested);
    on<DeletedItemHandled>(_onDeletedItemHandled);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<ListRenamed>(_onListRenamed);
    on<ListCurrencyChanged>(_onListCurrencyChanged);
    on<ListDeleted>(_onListDeleted);
    on<MessageHandled>(_onMessageHandled);
    on<SeedSampleItems>(_onSeedSampleItems);
  }

  final WatchListDetail _watchListDetail;
  final SetItemBought _setItemBought;
  final DeleteItem _deleteItem;
  final RestoreItem _restoreItem;
  final RenameList _renameList;
  final SetListCurrency _setListCurrency;
  final DeleteList _deleteList;
  final AddItem _addItem;

  String? _currentListId;

  Future<void> _onStarted(
    ListDetailStarted event,
    Emitter<ListDetailState> emit,
  ) async {
    _currentListId = event.listId;
    emit(state.copyWith(status: ListDetailStatus.loading));

    await emit.forEach(
      _watchListDetail(event.listId),
      onData: (result) => result.fold(
        (failure) => state.copyWith(
          status: ListDetailStatus.failure,
          message: FailureMessages.couldNotLoadList,
        ),
        (detail) => state.copyWith(
          status: ListDetailStatus.success,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _onRetried(
    ListDetailRetried event,
    Emitter<ListDetailState> emit,
  ) async {
    if (_currentListId == null) return;
    emit(state.copyWith(status: ListDetailStatus.loading));

    await emit.forEach(
      _watchListDetail(_currentListId!),
      onData: (result) => result.fold(
        (failure) => state.copyWith(
          status: ListDetailStatus.failure,
          message: FailureMessages.couldNotLoadList,
        ),
        (detail) => state.copyWith(
          status: ListDetailStatus.success,
          detail: detail,
        ),
      ),
    );
  }

  Future<void> _onItemBoughtToggled(
    ItemBoughtToggled event,
    Emitter<ListDetailState> emit,
  ) async {
    final result = await _setItemBought(
      SetItemBoughtParams(
        itemId: event.itemId,
        isBought: event.isBought,
      ),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        message: FailureMessages.databaseErrorSave,
      )),
      (_) {},
    );
  }

  Future<void> _onItemDeleted(
    ItemDeleted event,
    Emitter<ListDetailState> emit,
  ) async {
    final result = await _deleteItem(event.itemId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        message: FailureMessages.databaseErrorSave,
      )),
      (deletedItem) => emit(state.copyWith(
        deletedItem: deletedItem,
      )),
    );
  }

  Future<void> _onItemRestoreRequested(
    ItemRestoreRequested event,
    Emitter<ListDetailState> emit,
  ) async {
    emit(state.copyWith(clearDeletedItem: true));

    final result = await _restoreItem(event.item);
    if (isClosed) return;

    result.fold(
      (failure) {
        final message = failure is LimitFailure
            ? FailureMessages.undoItemsLimitReached
            : FailureMessages.databaseErrorSave;
        emit(state.copyWith(message: message));
      },
      (_) {},
    );
  }

  void _onDeletedItemHandled(
    DeletedItemHandled event,
    Emitter<ListDetailState> emit,
  ) {
    emit(state.copyWith(clearDeletedItem: true));
  }

  void _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<ListDetailState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  Future<void> _onListRenamed(
    ListRenamed event,
    Emitter<ListDetailState> emit,
  ) async {
    final listId = state.detail?.list.id ?? _currentListId;
    if (listId == null) return;

    final result = await _renameList(
      RenameListParams(listId: listId, name: event.name),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        final msg = failure is ValidationFailure
            ? failure.message
            : FailureMessages.databaseErrorSave;
        emit(state.copyWith(message: msg));
      },
      (_) {},
    );
  }

  Future<void> _onListCurrencyChanged(
    ListCurrencyChanged event,
    Emitter<ListDetailState> emit,
  ) async {
    final listId = state.detail?.list.id ?? _currentListId;
    if (listId == null) return;

    final result = await _setListCurrency(
      SetListCurrencyParams(listId: listId, currency: event.currency),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        message: FailureMessages.databaseErrorSave,
      )),
      (_) {},
    );
  }

  Future<void> _onListDeleted(
    ListDeleted event,
    Emitter<ListDetailState> emit,
  ) async {
    final listId = state.detail?.list.id ?? _currentListId;
    if (listId == null) return;

    final result = await _deleteList(listId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        message: FailureMessages.databaseErrorSave,
      )),
      (_) => emit(state.copyWith(listRemoved: true)),
    );
  }

  void _onMessageHandled(
    MessageHandled event,
    Emitter<ListDetailState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }

  Future<void> _onSeedSampleItems(
    SeedSampleItems event,
    Emitter<ListDetailState> emit,
  ) async {
    if (!kDebugMode) return;
    final listId = state.detail?.list.id ?? _currentListId;
    if (listId == null) return;

    final samples = [
      (name: 'Tomatoes', qty: 2500, unit: 'kg', price: 150000),
      (name: 'Onions', qty: 1000, unit: 'kg', price: 80000),
      (name: 'Rice', qty: 5000, unit: 'kg', price: 320000),
      (name: 'Cooking oil', qty: 2000, unit: 'L', price: 250000),
      (name: 'Bread', qty: 1000, unit: 'piece', price: 60000),
    ];

    for (final sample in samples) {
      await _addItem(
        AddItemParams(
          listId: listId,
          draft: ItemDraft(
            name: sample.name,
            quantity: Quantity.fromMilli(sample.qty),
            unit: sample.unit,
            unitPrice: Money.fromMinor(sample.price),
          ),
        ),
      );
    }
  }
}
