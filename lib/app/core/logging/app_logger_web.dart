import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';

AppLogger createAppLogger() => _WebAppLogger();

final class _WebAppLogger implements AppLogger {
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    web.console.info(formatLogEntry(message, error, stackTrace).toJS);
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    web.console.warn(formatLogEntry(message, error, stackTrace).toJS);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    web.console.error(formatLogEntry(message, error, stackTrace).toJS);
  }
}
