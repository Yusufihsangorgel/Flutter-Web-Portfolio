// Stub implementation for non-web platforms — all sound operations are no-ops.

import 'package:get/get.dart';

/// No-op sound controller for non-web platforms.
class SoundController extends GetxController {
  final RxBool isEnabled = false.obs;
  final RxDouble masterVolume = 0.5.obs;
  final RxBool isAmbientPlaying = false.obs;

  void toggleSound() => isEnabled.value = !isEnabled.value;
  void setMasterVolume(double volume) => masterVolume.value = volume;

  void playHover() {}
  void playClick() {}
  void playTransition() {}
  void playToggle({bool on = true}) {}
  void playSuccess() {}
  void playType() {}
  void playAmbient() {}
  void stopAmbient() {}
}
