import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/domain/value_objects/currency_code.dart';
import 'package:market_list/core/error/failures.dart';
import 'package:market_list/core/usecase/usecase.dart';
import 'package:market_list/core/widgets/failure_messages.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/create_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/delete_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/duplicate_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/rename_list.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/set_list_currency.dart';
import 'package:market_list/features/shopping_lists/domain/usecases/watch_lists.dart';
import 'package:market_list/features/shopping_lists/presentation/cubit/lists_state.dart';

class ListsCubit extends Cubit<ListsState> {
  ListsCubit({
    required WatchLists watchLists,
    required CreateList createList,
    required RenameList renameList,
    required SetListCurrency setListCurrency,
    required DeleteList deleteList,
    required DuplicateList duplicateList,
  })  : _watchLists = watchLists,
        _createList = createList,
        _renameList = renameList,
        _setListCurrency = setListCurrency,
        _deleteList = deleteList,
        _duplicateList = duplicateList,
        super(const ListsState.initial());

  final WatchLists _watchLists;
  final CreateList _createList;
  final RenameList _renameList;
  final SetListCurrency _setListCurrency;
  final DeleteList _deleteList;
  final DuplicateList _duplicateList;

  StreamSubscription<Either<Failure, List<ListSummary>>>? _listsSubscription;

  void watch() {
    emit(state.copyWith(status: ListsStatus.loading));
    _listsSubscription?.cancel();
    _listsSubscription = _watchLists(const NoParams()).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(
            state.copyWith(
              status: ListsStatus.failure,
              message: FailureMessages.couldNotLoadLists,
            ),
          ),
          (lists) => emit(
            state.copyWith(
              status: ListsStatus.success,
              lists: lists,
            ),
          ),
        );
      },
    );
  }

  void retry() {
    watch();
  }

  Future<void> createList(String name, CurrencyCode defaultCurrency) async {
    final result = await _createList(
      CreateListParams(name: name, currency: defaultCurrency),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(message: FailureMessages.mapFailureToMessage(failure)),
      ),
      (list) => emit(state.copyWith(createdListId: list.id)),
    );
  }

  Future<void> renameList(String id, String name) async {
    final result = await _renameList(
      RenameListParams(listId: id, name: name),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(message: FailureMessages.mapFailureToMessage(failure)),
      ),
      (_) {},
    );
  }

  Future<void> setCurrency(String id, CurrencyCode currency) async {
    final result = await _setListCurrency(
      SetListCurrencyParams(listId: id, currency: currency),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(message: FailureMessages.mapFailureToMessage(failure)),
      ),
      (_) {},
    );
  }

  Future<void> deleteList(String id) async {
    final result = await _deleteList(id);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(message: FailureMessages.mapFailureToMessage(failure)),
      ),
      (_) {},
    );
  }

  Future<void> duplicateList(String id) async {
    final result = await _duplicateList(id);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(message: FailureMessages.mapFailureToMessage(failure)),
      ),
      (_) {},
    );
  }

  void messageHandled() {
    emit(state.copyWith(clearMessage: true));
  }

  void createdListHandled() {
    emit(state.copyWith(clearCreatedListId: true));
  }

  @override
  Future<void> close() {
    _listsSubscription?.cancel();
    return super.close();
  }
}
