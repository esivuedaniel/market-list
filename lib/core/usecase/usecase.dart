import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:market_list/core/error/failures.dart';

abstract class UseCase<Output, Params> {
  Future<Either<Failure, Output>> call(Params params);
}

abstract class StreamUseCase<Output, Params> {
  Stream<Either<Failure, Output>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
