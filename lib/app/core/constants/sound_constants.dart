/// Constants for the synthesized sound design system.
///
/// All sounds are generated via Web Audio API oscillators — no audio files
/// required. Each category defines frequency, waveform, duration, and default
/// gain so the [SoundController] can reproduce them deterministically.
final class SoundConstants {
  const SoundConstants._();

  // ── Storage keys ─────────────────────────────────────────────────────
  static const storageKeyEnabled = 'soundEnabled';
  static const storageKeyVolume = 'soundMasterVolume';

  // ── Master defaults ──────────────────────────────────────────────────
  static const double defaultMasterVolume = 0.5;
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;

  // ── Sound pool ───────────────────────────────────────────────────────
  /// Maximum concurrent oscillator voices before oldest is dropped.
  static const int maxConcurrentSounds = 8;

  // ── Fade durations (seconds) ─────────────────────────────────────────
  static const double fadeInDuration = 0.01;
  static const double defaultDecay = 0.05;
  static const double ambientFadeIn = 1.0;
  static const double ambientFadeOut = 1.5;

  // ── Hover: short 2 kHz sine beep ────────────────────────────────────
  static const double hoverFrequency = 2000.0;
  static const String hoverWaveform = 'sine';
  static const double hoverDuration = 0.05; // 50 ms
  static const double hoverGain = 0.04;

  // ── Click: 800 Hz square wave with quick decay ──────────────────────
  static const double clickFrequency = 800.0;
  static const String clickWaveform = 'square';
  static const double clickDuration = 0.08; // 80 ms
  static const double clickGain = 0.06;

  // ── Transition: frequency sweep 200 Hz → 800 Hz ─────────────────────
  static const double transitionStartFrequency = 200.0;
  static const double transitionEndFrequency = 800.0;
  static const String transitionWaveform = 'sine';
  static const double transitionDuration = 0.30; // 300 ms
  static const double transitionGain = 0.05;

  // ── Toggle: two-tone beep ───────────────────────────────────────────
  static const double toggleFrequencyOn = 880.0;
  static const double toggleFrequencyOff = 660.0;
  static const String toggleWaveform = 'sine';
  static const double toggleNoteDuration = 0.05; // 50 ms per note
  static const double toggleGap = 0.05; // 50 ms gap
  static const double toggleGain = 0.05;

  // ── Type: 3 kHz sine blip ──────────────────────────────────────────
  static const double typeFrequency = 3000.0;
  static const String typeWaveform = 'sine';
  static const double typeDuration = 0.03; // 30 ms
  static const double typeGain = 0.03;

  // ── Success: ascending three-note arpeggio ──────────────────────────
  static const List<double> successFrequencies = [523.25, 659.25, 783.99]; // C5, E5, G5
  static const String successWaveform = 'sine';
  static const double successNoteDuration = 0.12; // 120 ms per note
  static const double successNoteGap = 0.08; // 80 ms gap
  static const double successGain = 0.07;

  // ── Ambient: low-frequency drone with subtle oscillation ────────────
  static const double ambientBaseFrequency = 60.0;
  static const double ambientLfoFrequency = 0.3; // slow oscillation
  static const double ambientLfoDepth = 10.0; // ±10 Hz wobble
  static const String ambientWaveform = 'sine';
  static const double ambientGain = 0.02;
}
