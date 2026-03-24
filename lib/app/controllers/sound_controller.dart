// Platform-agnostic sound controller.
//
// Uses conditional imports so non-web builds compile without `package:web`.
export 'sound_controller_stub.dart'
    if (dart.library.js_interop) 'sound_controller_web.dart';
