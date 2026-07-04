import 'package:equatable/equatable.dart';

/// Domain-level failure. Carries a technical [message] for logs only —
/// presentation maps the failure type to a localized string, never this
/// message directly (keeps i18n parity enforceable on widget strings).
abstract class Failure extends Equatable {
  const Failure([this.message = '']);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}
