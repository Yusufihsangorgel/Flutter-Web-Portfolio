import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/core/logging/app_logger.dart';

final class AppErrorHandlers {
  AppErrorHandlers(this.logger);

  final AppLogger logger;

  void install() {
    FlutterError.onError = (details) {
      if (kDebugMode) FlutterError.presentError(details);
      logger.error(
        'Flutter error',
        error: details.exception,
        stackTrace: details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      logger.error('Platform error', error: error, stackTrace: stackTrace);
      return true;
    };
  }

  void onZoneError(Object error, StackTrace stackTrace) {
    logger.error('Uncaught error', error: error, stackTrace: stackTrace);
  }
}
