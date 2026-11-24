import 'package:equatable/equatable.dart';

/// Immutable value object representing repository/service execution outcome.
class BaseResult<T> extends Equatable {
  final bool success;
  final String? code;
  final String? message;
  final dynamic messageParams;
  final T? data;

  const BaseResult({
    this.success = true,
    this.code,
    this.message,
    this.messageParams,
    this.data,
  });

  bool get isSuccess => success;
  bool get isError => !success;

  @override
  List<Object?> get props => [success, code, message, messageParams, data];
}
