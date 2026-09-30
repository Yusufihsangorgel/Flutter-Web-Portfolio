export 'app_logger_vm.dart'
    if (dart.library.js_interop) 'app_logger_web.dart'
    show createAppLogger;

abstract interface class AppLogger {
  void info(String message, {Object? error, StackTrace? stackTrace});

  void warning(String message, {Object? error, StackTrace? stackTrace});

  void error(String message, {Object? error, StackTrace? stackTrace});
}

String formatLogEntry(String message, Object? error, StackTrace? stackTrace) {
  final details = [
    message,
    if (error != null) error.toString(),
    if (stackTrace != null) stackTrace.toString(),
  ];
  return details.join('\n');
}
