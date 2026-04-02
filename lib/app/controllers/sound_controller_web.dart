import 'dart:developer' as dev;
import 'dart:js_interop';

import 'package:get/get.dart';
import 'package:web/web.dart' as web;

import 'package:flutter_web_portfolio/app/core/constants/sound_constants.dart';

/// Web Audio API-based sound design controller.
///
/// Synthesizes all sounds programmatically via [OscillatorNode] — no audio
/// files needed. Sounds are lazy-loaded (AudioContext created on first user
/// interaction) and pooled so overlapping playback works correctly.
///
/// Muted by default; user opts in via the sound toggle widget.
class SoundController extends GetxController {
  // ── Reactive state ──────────────────────────────────────────────────

  final RxBool isEnabled = false.obs;
  bool _hasUserInteracted = false;
  final RxDouble masterVolume = SoundConstants.defaultMasterVolume.obs;
  final RxBool isAmbientPlaying = false.obs;

  // ── Internals ───────────────────────────────────────────────────────

  web.AudioContext? _ctx;

  /// Active oscillator count for sound-pool limiting.
  int _activeVoices = 0;

  /// Nodes for the ambient loop so we can stop it cleanly.
  web.OscillatorNode? _ambientOsc;
  web.GainNode? _ambientGain;

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  @override
  void onClose() {
    stopAmbient();
    _ctx?.close();
    _ctx = null;
    super.onClose();
  }

  // ── Persistence via localStorage ────────────────────────────────────

  void _loadPreferences() {
    try {
      final storedEnabled = web.window.localStorage.getItem(
        SoundConstants.storageKeyEnabled,
      );
      if (storedEnabled != null) {
        isEnabled.value = storedEnabled == 'true';
      }

      final storedVolume = web.window.localStorage.getItem(
        SoundConstants.storageKeyVolume,
      );
      if (storedVolume != null) {
        final parsed = double.tryParse(storedVolume);
        if (parsed != null) {
          masterVolume.value = parsed.clamp(
            SoundConstants.minVolume,
            SoundConstants.maxVolume,
          );
        }
      }
    } catch (e) {
      dev.log('Failed to load sound preferences from localStorage', name: 'SoundController', error: e);
    }
  }

  void _savePreferences() {
    try {
      web.window.localStorage.setItem(
        SoundConstants.storageKeyEnabled,
        isEnabled.value.toString(),
      );
      web.window.localStorage.setItem(
        SoundConstants.storageKeyVolume,
        masterVolume.value.toString(),
      );
    } catch (e) {
      dev.log('Failed to save sound preferences to localStorage', name: 'SoundController', error: e);
    }
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// Toggle sound on/off and persist.
  void toggleSound() {
    _hasUserInteracted = true;
    isEnabled.value = !isEnabled.value;
    _savePreferences();

    if (isEnabled.value) {
      _ensureContext();
    } else {
      stopAmbient();
    }
  }

  /// Set master volume (0.0–1.0) and persist.
  void setMasterVolume(double volume) {
    masterVolume.value = volume.clamp(
      SoundConstants.minVolume,
      SoundConstants.maxVolume,
    );
    _savePreferences();

    // Update ambient gain in real time if playing.
    final ag = _ambientGain;
    if (ag != null && isAmbientPlaying.value) {
      ag.gain.value = SoundConstants.ambientGain * masterVolume.value;
    }
  }

  // ── Sound methods ───────────────────────────────────────────────────

  /// Short 2 kHz sine beep — subtle hover feedback.
  void playHover() {
    if (!_canPlay()) return;
    _playTone(
      frequency: SoundConstants.hoverFrequency,
      waveform: SoundConstants.hoverWaveform,
      duration: SoundConstants.hoverDuration,
      gain: SoundConstants.hoverGain,
    );
  }

  /// 800 Hz square wave with quick decay — satisfying click.
  void playClick() {
    if (!_canPlay()) return;
    _playTone(
      frequency: SoundConstants.clickFrequency,
      waveform: SoundConstants.clickWaveform,
      duration: SoundConstants.clickDuration,
      gain: SoundConstants.clickGain,
    );
  }

  /// Frequency sweep 200 → 800 Hz — section transition whoosh.
  void playTransition() {
    if (!_canPlay()) return;
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    final now = ctx.currentTime;
    final gain = _scaledGain(SoundConstants.transitionGain);

    final osc = ctx.createOscillator()..type = SoundConstants.transitionWaveform;
    osc.frequency.value = SoundConstants.transitionStartFrequency;
    osc.frequency.exponentialRampToValueAtTime(
      SoundConstants.transitionEndFrequency,
      now + SoundConstants.transitionDuration,
    );

    final gainNode = ctx.createGain()..gain.value = gain;
    gainNode.gain.exponentialRampToValueAtTime(
      0.001,
      now + SoundConstants.transitionDuration,
    );

    osc.connect(gainNode);
    gainNode.connect(ctx.destination);

    _startAndStop(osc, now, SoundConstants.transitionDuration);
  }

  /// Two-tone beep — toggle switch feedback.
  /// [on] selects the ascending or descending tone pair.
  void playToggle({bool on = true}) {
    if (!_canPlay()) return;
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    final now = ctx.currentTime;
    final gain = _scaledGain(SoundConstants.toggleGain);
    final freq1 = on ? SoundConstants.toggleFrequencyOff : SoundConstants.toggleFrequencyOn;
    final freq2 = on ? SoundConstants.toggleFrequencyOn : SoundConstants.toggleFrequencyOff;

    // First note.
    _playToneAt(
      time: now,
      frequency: freq1,
      waveform: SoundConstants.toggleWaveform,
      duration: SoundConstants.toggleNoteDuration,
      gain: gain,
    );

    // Second note after gap.
    _playToneAt(
      time: now + SoundConstants.toggleNoteDuration + SoundConstants.toggleGap,
      frequency: freq2,
      waveform: SoundConstants.toggleWaveform,
      duration: SoundConstants.toggleNoteDuration,
      gain: gain,
    );
  }

  /// Ascending three-note arpeggio — form submission celebration.
  void playSuccess() {
    if (!_canPlay()) return;
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    final now = ctx.currentTime;
    final gain = _scaledGain(SoundConstants.successGain);

    for (var i = 0; i < SoundConstants.successFrequencies.length; i++) {
      final noteStart = now +
          i * (SoundConstants.successNoteDuration + SoundConstants.successNoteGap);
      _playToneAt(
        time: noteStart,
        frequency: SoundConstants.successFrequencies[i],
        waveform: SoundConstants.successWaveform,
        duration: SoundConstants.successNoteDuration,
        gain: gain,
      );
    }
  }

  /// Soft 3 kHz blip — typewriter keystroke.
  void playType() {
    if (!_canPlay()) return;
    _playTone(
      frequency: SoundConstants.typeFrequency,
      waveform: SoundConstants.typeWaveform,
      duration: SoundConstants.typeDuration,
      gain: SoundConstants.typeGain,
    );
  }

  /// Low-frequency drone with subtle LFO wobble — optional ambient loop.
  void playAmbient() {
    if (!_canPlay() || isAmbientPlaying.value) return;
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    final now = ctx.currentTime;
    final gain = _scaledGain(SoundConstants.ambientGain);

    // Main drone oscillator with frequency wobble baked into the schedule.
    final osc = ctx.createOscillator()
      ..type = SoundConstants.ambientWaveform;
    osc.frequency.value = SoundConstants.ambientBaseFrequency;

    // Simulate LFO by scheduling repeating frequency ramps.
    // Each cycle: base → base+depth → base over 1/lfoFreq seconds.
    const cycleDuration = 1.0 / SoundConstants.ambientLfoFrequency;
    const halfCycle = cycleDuration / 2.0;
    const lo = SoundConstants.ambientBaseFrequency - SoundConstants.ambientLfoDepth;
    const hi = SoundConstants.ambientBaseFrequency + SoundConstants.ambientLfoDepth;

    // Schedule several cycles ahead (browser will loop naturally).
    const scheduledCycles = 120; // ~6–7 minutes at 0.3 Hz
    for (var i = 0; i < scheduledCycles; i++) {
      final cycleStart = now + i * cycleDuration;
      osc.frequency.linearRampToValueAtTime(hi, cycleStart + halfCycle);
      osc.frequency.linearRampToValueAtTime(lo, cycleStart + cycleDuration);
    }

    // Master gain with fade-in.
    final masterGain = ctx.createGain()..gain.value = 0.001;
    masterGain.gain.exponentialRampToValueAtTime(
      gain.clamp(0.001, 1.0),
      now + SoundConstants.ambientFadeIn,
    );

    osc.connect(masterGain);
    masterGain.connect(ctx.destination);

    osc.start(now);

    _ambientOsc = osc;
    _ambientGain = masterGain;
    isAmbientPlaying.value = true;
  }

  /// Fade out and stop the ambient drone.
  void stopAmbient() {
    if (!isAmbientPlaying.value) return;

    final ctx = _ctx;
    final osc = _ambientOsc;
    final gain = _ambientGain;

    if (ctx != null && osc != null && gain != null) {
      final now = ctx.currentTime;
      gain.gain.exponentialRampToValueAtTime(
        0.001,
        now + SoundConstants.ambientFadeOut,
      );
      osc.stop(now + SoundConstants.ambientFadeOut + 0.05);
    }

    _ambientOsc = null;
    _ambientGain = null;
    isAmbientPlaying.value = false;
  }

  // ── Internal helpers ────────────────────────────────────────────────

  /// Whether we should play a sound right now.
  bool _canPlay() {
    if (!isEnabled.value) return false;
    if (!_hasUserInteracted) return false;
    if (_prefersReducedMotion()) return false;
    return true;
  }

  /// Respect the `prefers-reduced-motion` media query as a proxy for
  /// reduced-sound preferences — many accessibility users prefer both.
  bool _prefersReducedMotion() {
    try {
      return web.window
          .matchMedia('(prefers-reduced-motion: reduce)')
          .matches;
    } catch (e) {
      dev.log('Failed to query prefers-reduced-motion', name: 'SoundController', error: e);
      return false;
    }
  }

  /// Lazily create the AudioContext (browser autoplay policy requires
  /// creation inside a user-gesture handler).
  void _ensureContext() {
    _ctx ??= web.AudioContext();
    if (_ctx!.state == 'suspended') {
      _ctx!.resume();
    }
  }

  /// Scale a per-sound gain by master volume.
  double _scaledGain(double baseGain) => baseGain * masterVolume.value;

  /// Play a single oscillator tone immediately.
  void _playTone({
    required double frequency,
    required String waveform,
    required double duration,
    required double gain,
  }) {
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    _playToneAt(
      time: ctx.currentTime,
      frequency: frequency,
      waveform: waveform,
      duration: duration,
      gain: _scaledGain(gain),
    );
  }

  /// Play a tone at a specific AudioContext time — used for scheduling
  /// multi-note sequences (toggle, success arpeggio).
  void _playToneAt({
    required double time,
    required double frequency,
    required String waveform,
    required double duration,
    required double gain,
  }) {
    final ctx = _ctx;
    if (ctx == null) return;
    if (_activeVoices >= SoundConstants.maxConcurrentSounds) return;

    final osc = ctx.createOscillator()..type = waveform;
    osc.frequency.value = frequency;

    final gainNode = ctx.createGain()..gain.value = gain;
    gainNode.gain.exponentialRampToValueAtTime(0.001, time + duration);

    osc.connect(gainNode);
    gainNode.connect(ctx.destination);

    _startAndStop(osc, time, duration);
  }

  /// Start an oscillator and schedule its stop, tracking the sound pool.
  void _startAndStop(web.OscillatorNode osc, double time, double duration) {
    _activeVoices++;
    osc
      ..start(time)
      ..stop(time + duration + SoundConstants.defaultDecay);

    // Use the ended event to decrement voice count.
    void onEnded(web.Event _) {
      _activeVoices = (_activeVoices - 1).clamp(0, SoundConstants.maxConcurrentSounds);
    }

    osc.addEventListener('ended', onEnded.toJS);
  }
}
