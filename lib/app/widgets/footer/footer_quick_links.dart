part of '../premium_footer.dart';

// =============================================================================
// Center column: Quick navigation links with hover effects
// =============================================================================

class _QuickLinksColumn extends StatelessWidget {
  const _QuickLinksColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    const brightColor = AppColors.textBright;

    return BlocBuilder<LanguageCubit, LanguageState>(
      buildWhen: (previous, current) =>
          previous.languageCode != current.languageCode ||
          !identical(previous.translations, current.translations),
      builder: (context, state) {
        final lang = context.read<LanguageCubit>();
        final sections = [
          for (final section in lang.activeSections)
            _QuickLinkItem(
              section,
              lang.getText(
                'nav.$section',
                defaultValue:
                    '${section[0].toUpperCase()}${section.substring(1)}',
              ),
            ),
        ];

        return Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.getText('footer.quick_links', defaultValue: 'Quick Links'),
              style: AppFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: brightColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ...sections.map(
              (item) => _QuickLinkButton(
                sectionId: item.id,
                label: item.label,
                centered: centered,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickLinkItem {
  const _QuickLinkItem(this.id, this.label);
  final String id;
  final String label;
}

/// A single quick link with an expanding accent dash on hover.
class _QuickLinkButton extends StatefulWidget {
  const _QuickLinkButton({
    required this.sectionId,
    required this.label,
    this.centered = false,
  });

  final String sectionId;
  final String label;
  final bool centered;

  @override
  State<_QuickLinkButton> createState() => _QuickLinkButtonState();
}

class _QuickLinkButtonState extends State<_QuickLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.read<SoundController>().playClick();
            context.read<AppScrollController>().scrollToSection(
              widget.sectionId,
            );
          },
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: CinematicCurves.hoverLift,
            transform: Matrix4.translationValues(
              _hovered && !widget.centered ? 6 : 0,
              0,
              0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expanding accent dash indicator
                AnimatedContainer(
                  duration: AppDurations.fast,
                  width: _hovered ? 20 : 0,
                  height: 1,
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
                if (_hovered) const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 13,
                    color: _hovered ? AppColors.accent : baseColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
