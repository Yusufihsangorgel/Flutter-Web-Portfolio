import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_error_handlers.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';

void main() {
  test('uncaught zone errors reach the logger with their stack', () {
    final logger = _FakeLogger();
    final handlers = AppErrorHandlers(logger);
    final failure = StateError('zone failure');
    final stack = StackTrace.current;

    runZonedGuarded(
      () => Zone.current.handleUncaughtError(failure, stack),
      handlers.onZoneError,
    );

    expect(logger.lastMessage, 'Uncaught error');
    expect(logger.lastError, same(failure));
    expect(logger.lastStack, same(stack));
  });

  test('Flutter and platform errors reach the logger', () {
    final logger = _FakeLogger();
    final previousFlutterHandler = FlutterError.onError;
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    addTearDown(() {
      FlutterError.onError = previousFlutterHandler;
      PlatformDispatcher.instance.onError = previousPlatformHandler;
    });
    AppErrorHandlers(logger).install();
    final failure = StateError('framework failure');
    final stack = StackTrace.current;

    FlutterError.onError!(
      FlutterErrorDetails(exception: failure, stack: stack),
    );
    expect(logger.lastMessage, 'Flutter error');
    expect(logger.lastError, same(failure));
    expect(logger.lastStack, same(stack));

    expect(PlatformDispatcher.instance.onError!(failure, stack), isTrue);
    expect(logger.lastMessage, 'Platform error');
    expect(logger.lastError, same(failure));
    expect(logger.lastStack, same(stack));
  });
}

final class _FakeLogger implements AppLogger {
  String? lastMessage;
  Object? lastError;
  StackTrace? lastStack;

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    lastMessage = message;
    lastError = error;
    lastStack = stackTrace;
  }
}
