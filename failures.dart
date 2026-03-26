// lib/core/errors/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class FirestoreFailure extends Failure {
  const FirestoreFailure({required super.message, super.code});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}

class ScorerTokenFailure extends Failure {
  const ScorerTokenFailure({required super.message, super.code});
}

// lib/core/errors/exceptions.dart
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

class FirestoreException extends AppException {
  const FirestoreException({required super.message, super.code});
}

class ScorerTokenException extends AppException {
  const ScorerTokenException({required super.message, super.code});
}

class PermissionException extends AppException {
  const PermissionException({required super.message, super.code});
}
