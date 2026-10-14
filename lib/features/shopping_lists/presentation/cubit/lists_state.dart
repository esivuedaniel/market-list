import 'package:equatable/equatable.dart';
import 'package:market_list/features/shopping_lists/domain/entities/list_summary.dart';

enum ListsStatus {
  loading,
  success,
  failure,
}

class ListsState extends Equatable {
  const ListsState({
    required this.status,
    this.lists = const [],
    this.message,
    this.createdListId,
  });

  const ListsState.initial()
      : status = ListsStatus.loading,
        lists = const [],
        message = null,
        createdListId = null;

  final ListsStatus status;
  final List<ListSummary> lists;
  final String? message;
  final String? createdListId;

  bool get isEmpty => status == ListsStatus.success && lists.isEmpty;

  ListsState copyWith({
    ListsStatus? status,
    List<ListSummary>? lists,
    String? message,
    String? createdListId,
    bool clearMessage = false,
    bool clearCreatedListId = false,
  }) {
    return ListsState(
      status: status ?? this.status,
      lists: lists ?? this.lists,
      message: clearMessage ? null : (message ?? this.message),
      createdListId: clearCreatedListId
          ? null
          : (createdListId ?? this.createdListId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        lists,
        message,
        createdListId,
      ];
}
