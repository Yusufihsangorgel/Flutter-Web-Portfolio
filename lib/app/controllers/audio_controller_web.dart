import 'package:get/get.dart';
import 'package:web/web.dart' as web;

/// Web Audio API-based controller for subtle UI sound feedback.
///
/// Synthesizes short tick/click sounds — no audio files needed.
/// Muted by default; user opts in via the AppBar speaker toggle.
class AudioController extends GetxController {
  static const _storageKey = 'audioMuted';

  final RxBool isMuted = true.obs;

  web.AudioContext? _ctx;

  @override
  void onInit() {
    super.onInit();
    _loadMutePreference();
  }

  // ── Persistence ──────────────────────────────────────────────────────

  void _loadMutePreference() {
    try {
      final stored = web.window.localStorage.getItem(_storageKey);
      if (stored != null) {
        isMuted.value = stored == 'true';
      }
      // If nothing stored, keep default (muted).
    } catch (_) {
      // localStorage unavailable — stay muted.
    }
  }

  void _saveMutePreference() {
    try {
      web.window.localStorage.setItem(_storageKey, isMuted.value.toString());
    } catch (_) {
      // Ignore write failures.
    }
  }

  /// Toggle mute state and persist.
  void toggleMute() {
    isMuted.value = !isMuted.value;
    _saveMutePreference();
    // Resume AudioContext on first unmute (browser autoplay policy).
    if (!isMuted.value) _ensureContext();
  }

  // ── Sound synthesis ──────────────────────────────────────────────────

  void _ensureContext() {
    _ctx ??= web.AudioContext();
    if (_ctx!.state == 'suspended') {
      _ctx!.resume();
    }
  }

  /// Short, subtle tick — hover feedback.
  void playHover() {
    if (isMuted.value) return;
    _ensureContext();
    _playTone(frequency: 1800, duration: 0.03, gain: 0.04);
  }

  /// Slightly louder click — tap/press feedback.
  void playClick() {
    if (isMuted.value) return;
    _ensureContext();
    _playTone(frequency: 1200, duration: 0.06, gain: 0.08);
  }

  /// Synthesizes a short sine-wave tone with a fast exponential decay.
  void _playTone({
    required double frequency,
    required double duration,
    required double gain,
  }) {
    final ctx = _ctx;
    if (ctx == null) return;

    final now = ctx.currentTime;

    final oscillator = ctx.createOscillator()
      ..type = 'sine';
    oscillator.frequency.value = frequency;

    final gainNode = ctx.createGain()
      ..gain.value = gain;
    // Fast exponential ramp-down for a clean click envelope.
    gainNode.gain.exponentialRampToValueAtTime(0.001, now + duration);

    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);
    oscillator
      ..start(now)
      ..stop(now + duration);
  }
}
