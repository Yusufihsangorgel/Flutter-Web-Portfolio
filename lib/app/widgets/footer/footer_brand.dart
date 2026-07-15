part of '../premium_footer.dart';

// =============================================================================
// Left column: Logo, tagline, copyright with easter egg
// =============================================================================

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final languageController = context.read<LanguageCubit>();
    const secondaryColor = AppColors.textSecondary;
    const brightColor = AppColors.textBright;

    return BlocBuilder<LanguageCubit, LanguageState>(
      buildWhen: (previous, current) =>
          previous.languageCode != current.languageCode ||
          !identical(previous.translations, current.translations),
      builder: (context, state) {
        final data =
            languageController.cvData['personal_info']
                as Map<String, dynamic>? ??
            <String, dynamic>{};
        final name = (data['name'] as String?) ?? 'Your Name';

        return Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Neon name / logo ──────────────────────────────────────
            NeonText(
              text: name,
              style: AppFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: brightColor,
              ),
              intensity: 0.6,
              blurRadius: 14,
              animated: true,
            ),
            const SizedBox(height: 12),

            // ── Tagline ───────────────────────────────────────────────
            Text(
              languageController.getText(
                'cv_data.personal_info.tagline',
                defaultValue: 'Building digital experiences',
              ),
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: AppFonts.jetBrainsMono(
                fontSize: 13,
                color: secondaryColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // ── Copyright with 5-click easter egg ─────────────────────
            _CopyrightEasterEgg(name: name, centered: centered),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Copyright with 5-click easter egg
// =============================================================================

class _CopyrightEasterEgg extends StatefulWidget {
  const _CopyrightEasterEgg({required this.name, this.centered = false});

  final String name;
  final bool centered;

  @override
  State<_CopyrightEasterEgg> createState() => _CopyrightEasterEggState();
}

class _CopyrightEasterEggState extends State<_CopyrightEasterEgg>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  bool _easterEggVisible = false;
  late final AnimationController _eggCtrl;
  late final Animation<double> _eggAnimation;

  @override
  void initState() {
    super.initState();
    _eggCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _eggAnimation = CurvedAnimation(
      parent: _eggCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
  }

  @override
  void dispose() {
    _eggCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      setState(() => _easterEggVisible = true);
      _eggCtrl.forward(from: 0);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _eggCtrl.reverse().then((_) {
            if (mounted) setState(() => _easterEggVisible = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final language = context.read<LanguageCubit>();
    const secondaryColor = AppColors.textSecondary;

    return Column(
      crossAxisAlignment: widget.centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          excludeFromSemantics: true,
          onTap: _onTap,
          child: Text(
            '\u00A9 $year ${widget.name}',
            style: AppFonts.jetBrainsMono(fontSize: 12, color: secondaryColor),
          ),
        ),
        if (_easterEggVisible)
          AnimatedBuilder(
            animation: _eggAnimation,
            builder: (_, _) {
              final v = _eggAnimation.value;
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - v)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        language.getText(
                          'footer.easter_egg',
                          defaultValue:
                              'You found the five-click path. Curiosity is '
                              'part of the test surface.',
                        ),
                        style: AppFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
