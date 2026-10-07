import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_error_handlers.dart';

import '../../../support/fake_app_logger.dart';

void main() {
  test('uncaught zone errors reach the logger with their stack', () {
    final logger = FakeAppLogger();
    final handlers = AppErrorHandlers(logger);
    final failure = StateError('zone failure');
    final stack = StackTrace.current;

    runZonedGuarded(
      () => Zone.current.handleUncaughtError(failure, stack),
      handlers.onZoneError,
    );

    expect(logger.message, 'Uncaught error');
    expect(logger.errorValue, same(failure));
    expect(logger.stackTrace, same(stack));
  });

  test('Flutter and platform errors reach the logger', () {
    final logger = FakeAppLogger();
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
    expect(logger.message, 'Flutter error');
    expect(logger.errorValue, same(failure));
    expect(logger.stackTrace, same(stack));

    expect(PlatformDispatcher.instance.onError!(failure, stack), isTrue);
    expect(logger.message, 'Platform error');
    expect(logger.errorValue, same(failure));
    expect(logger.stackTrace, same(stack));
  });
}
