part of '../premium_footer.dart';

// =============================================================================
// Bottom bar: Built with Flutter, version, powered by, command palette hint
// =============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 8,
        children: [
          // "Built with Flutter & <3" with pulsing heart
          const _BuiltWithFlutter(),
          // Version label
          Text(
            'v$_appVersion',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          // Powered by Flutter with spinning logo on hover
          const _PoweredByFlutter(),
          // Command palette keyboard shortcut hint
          const _CommandPaletteHint(),
        ],
      ),
    );
  }
}

// =============================================================================
// "Built with Flutter & <3" with animated heart
// =============================================================================

class _BuiltWithFlutter extends StatefulWidget {
  const _BuiltWithFlutter();

  @override
  State<_BuiltWithFlutter> createState() => _BuiltWithFlutterState();
}

class _BuiltWithFlutterState extends State<_BuiltWithFlutter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Built with Flutter & ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.6),
          ),
        ),
        AnimatedBuilder(
          animation: _heartCtrl,
          builder: (_, __) {
            final scale =
                0.85 + 0.3 * math.sin(_heartCtrl.value * math.pi);
            return Transform.scale(
              scale: scale,
              child: const Text(
                '\u2764\uFE0F',
                style: TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// "Powered by Flutter" with spinning logo on hover
// =============================================================================

class _PoweredByFlutter extends StatefulWidget {
  const _PoweredByFlutter();

  @override
  State<_PoweredByFlutter> createState() => _PoweredByFlutterState();
}

class _PoweredByFlutterState extends State<_PoweredByFlutter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _spinCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered by ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          AnimatedBuilder(
            animation: _spinCtrl,
            builder: (_, child) => Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.rotationY(_spinCtrl.value * 2 * math.pi),
                child: child,
              ),
            child: FlutterLogo(
              size: 14,
              style: FlutterLogoStyle.markOnly,
              textColor: _hovered
                  ? AppColors.accent
                  : secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Flutter',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: _hovered
                  ? AppColors.accent
                  : secondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Command palette hint
// =============================================================================

class _CommandPaletteHint extends StatelessWidget {
  const _CommandPaletteHint();

  @override
  Widget build(BuildContext context) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final shortcut = isMac ? '\u2318K' : 'Ctrl+K';
    const secondaryColor = AppColors.textSecondary;
    final languageController = Get.find<LanguageController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${languageController.getText('footer.command_hint_prefix', defaultValue: 'Press')} ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            shortcut,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          ' ${languageController.getText('footer.command_hint_suffix', defaultValue: 'to open command palette')}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
