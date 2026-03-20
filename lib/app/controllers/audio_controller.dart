// Platform-agnostic audio controller.
//
// Uses conditional imports so non-web builds compile without `package:web`.
export 'audio_controller_stub.dart'
    if (dart.library.js_interop) 'audio_controller_web.dart';
