import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Animated speaker icon that toggles the [SoundController] on/off.
///
/// Designed for placement in the app-bar action row. On toggle the icon
/// cross-fades between speaker-on and speaker-off states, and a brief
/// volume indicator pill fades in then out.
class SoundToggle extends StatefulWidget {
  const SoundToggle({super.key});

  @override
  State<SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<SoundToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _indicatorController;
  late final Animation<double> _indicatorOpacity;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _indicatorOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onToggle(SoundController controller) {
    controller.toggleSound();
    // Play the brief volume indicator animation.
    _indicatorController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SoundController>()) {
      return const SizedBox.shrink();
    }

    final controller = Get.find<SoundController>();
    const iconColor = AppColors.textPrimary;

    return Obx(() {
      final enabled = controller.isEnabled.value;

      return Semantics(
        label: enabled ? 'Mute sound effects' : 'Enable sound effects',
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Main toggle button ──────────────────────────────────
            IconButton(
              onPressed: () => _onToggle(controller),
              tooltip: enabled ? 'Mute sounds' : 'Unmute sounds',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.7, end: 1.0)
                        .animate(animation),
                    child: child,
                  ),
                ),
                child: Icon(
                  enabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  key: ValueKey(enabled),
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),

            // ── Volume indicator pill ───────────────────────────────
            Positioned(
              bottom: -4,
              child: FadeTransition(
                opacity: _indicatorOpacity,
                child: _VolumeIndicatorDot(enabled: enabled),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// Tiny coloured dot that briefly appears below the speaker icon on toggle.
class _VolumeIndicatorDot extends StatelessWidget {
  const _VolumeIndicatorDot({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: enabled
          ? const Color(0xFF10B981) // green accent
          : const Color(0xFFEF4444), // red accent
    ),
  );
}
