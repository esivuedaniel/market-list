import 'package:equatable/equatable.dart';

enum LimitKind {
  lists,
  items,
}

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

class ValidationFailure extends Failure {
  const ValidationFailure([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class LimitFailure extends Failure {
  const LimitFailure(this.kind);
  final LimitKind kind;

  @override
  List<Object?> get props => [kind];
}

class StorageFullFailure extends Failure {
  const StorageFullFailure();
}

class SchemaTooNewFailure extends Failure {
  const SchemaTooNewFailure();
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([this.details]);
  final String? details;

  @override
  List<Object?> get props => [details];
}

class ExportFailure extends Failure {
  const ExportFailure([this.details]);
  final String? details;

  @override
  List<Object?> get props => [details];
}

class ShareFailure extends Failure {
  const ShareFailure([this.details]);
  final String? details;

  @override
  List<Object?> get props => [details];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([this.details]);
  final String? details;

  @override
  List<Object?> get props => [details];
}
