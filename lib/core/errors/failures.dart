import 'package:equatable/equatable.dart';

/// Domain-level failure. Carries a technical [message] for logs only —
/// presentation maps the failure type/code to a localized string, never this
/// message directly (keeps i18n parity enforceable on widget strings).
abstract class Failure extends Equatable {
  const Failure([this.message = '']);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message, this.code]);

  /// The originating `FirebaseException.code`, when known — lets a caller
  /// (the offline mutation queue's replay loop) tell "still offline" apart
  /// from "the server actually rejected this" without parsing [message].
  /// Null for every failure that isn't wrapping a `FirebaseException`.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// Reasons an auth call can fail. The UI switches on this to pick a warm,
/// localized message — the raw Firebase message is never shown to users.
enum AuthFailureCode {
  invalidCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  userDisabled,
  network,
  unknown,
}

class AuthFailure extends Failure {
  const AuthFailure(this.code, [super.message]);

  final AuthFailureCode code;

  @override
  List<Object?> get props => [code, message];
}

/// Why the driver-assignment transaction (M9) rejected a candidate — the
/// owner assignment sheet switches on this to pick a reason-specific,
/// blame-free message instead of a generic failure.
enum DriverUnavailableReason { suspended, offline, capacity, area, status, taken }

class DriverUnavailable extends Failure {
  const DriverUnavailable(this.reason, [super.message]);

  final DriverUnavailableReason reason;

  @override
  List<Object?> get props => [reason, message];
}
