import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';

final class FakeAppLogger implements AppLogger {
  String? message;
  Object? errorValue;
  StackTrace? stackTrace;
  final errors = <String>[];

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    errors.add(message);
    this.message = message;
    errorValue = error;
    this.stackTrace = stackTrace;
  }
}
