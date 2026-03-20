// Platform-agnostic interface for browser URL manipulation.
//
// Uses conditional imports so non-web builds compile without `package:web`.
export 'web_url_strategy_stub.dart'
    if (dart.library.js_interop) 'web_url_strategy_web.dart';
