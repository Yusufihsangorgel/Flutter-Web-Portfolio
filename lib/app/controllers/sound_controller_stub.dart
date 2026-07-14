import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/sound_state.dart';
import 'package:flutter_web_portfolio/app/core/constants/sound_constants.dart';

/// No-op sound controller for non-web platforms.
final class SoundController extends Cubit<SoundState> {
  SoundController()
    : super(
        const SoundState.initial(
          masterVolume: SoundConstants.defaultMasterVolume,
        ),
      );

  void toggleSound() => emit(state.copyWith(isEnabled: !state.isEnabled));

  void setMasterVolume(double volume) => emit(
    state.copyWith(
      masterVolume: volume.clamp(
        SoundConstants.minVolume,
        SoundConstants.maxVolume,
      ),
    ),
  );

  void playHover() {}
  void playClick() {}
  void playTransition() {}
  void playToggle({bool on = true}) {}
  void playSuccess() {}
  void playType() {}
  void playAmbient() {}
  void stopAmbient() {}
}
