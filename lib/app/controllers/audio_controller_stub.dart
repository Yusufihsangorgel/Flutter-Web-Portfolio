// Stub implementation for non-web platforms — all audio operations are no-ops.

import 'package:get/get.dart';

/// No-op audio controller for non-web platforms.
class AudioController extends GetxController {
  final RxBool isMuted = true.obs;

  /// No-op on non-web platforms.
  void playHover() {}

  /// No-op on non-web platforms.
  void playClick() {}

  /// Toggles mute state (persisted nowhere on non-web).
  void toggleMute() => isMuted.value = !isMuted.value;
}
