import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';

AppLogger createAppLogger() => _VmAppLogger();

final class _VmAppLogger implements AppLogger {
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _write(message, 800, error, stackTrace);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _write(message, 900, error, stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _write(message, 1000, error, stackTrace);
  }

  void _write(
    String message,
    int level,
    Object? error,
    StackTrace? stackTrace,
  ) {
    dev.log(
      message,
      name: 'App',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      stderr.writeln(formatLogEntry(message, error, stackTrace));
    }
  }
}
