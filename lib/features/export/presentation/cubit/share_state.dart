import 'package:equatable/equatable.dart';

enum ShareStatus {
  idle,
  working,
  done,
  failure,
}

class ShareState extends Equatable {
  const ShareState({
    this.status = ShareStatus.idle,
    this.message,
  });

  final ShareStatus status;
  final String? message;

  ShareState copyWith({
    ShareStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return ShareState(
      status: status ?? this.status,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, message];
}
