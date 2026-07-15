import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';

/// A terminal chapter rather than a conventional three-column site footer.
class PremiumFooter extends StatelessWidget {
  const PremiumFooter({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final width = MediaQuery.sizeOf(context).width;
      final desktop = width >= Breakpoints.desktop;
      final personal =
          language.cvData['personal_info'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final name = personal['name'] as String? ?? 'Senior Flutter Engineer';
      final statement = language.getText(
        'footer.verification_body',
        defaultValue:
            'Building thoughtful Flutter products and the Go services behind them.',
      );

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: desktop ? 160 : 96),
        color: AppColors.textBright,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.background),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 72 : 24,
              desktop ? 54 : 38,
              desktop ? 72 : 24,
              26,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterRail(),
                SizedBox(height: desktop ? 70 : 48),
                Text(
                  statement,
                  style: AppFonts.instrumentSerif(
                    fontSize: desktop ? 92 : 48,
                    fontStyle: FontStyle.italic,
                    color: AppColors.background,
                    height: 0.93,
                    letterSpacing: desktop ? -3.2 : -1.4,
                  ),
                ),
                SizedBox(height: desktop ? 76 : 54),
                _FooterNavigation(language: language, desktop: desktop),
                const SizedBox(height: 44),
                _FooterBottom(name: name, language: language),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FooterRail extends StatelessWidget {
  const _FooterRail();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      children: [
        Text(
          '05 / SIGNAL END',
          style: AppFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.background,
            letterSpacing: 1.25,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Divider(color: Color(0x520B0B0D))),
        const SizedBox(width: 16),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.hotCoral,
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

class _FooterNavigation extends StatelessWidget {
  const _FooterNavigation({required this.language, required this.desktop});

  final LanguageCubit language;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final links = [
      for (final section in language.activeSections)
        if (section != 'home')
          (
            id: section,
            label: language.getText(
              'nav.$section',
              defaultValue:
                  '${section[0].toUpperCase()}${section.substring(1)}',
            ),
          ),
    ];
    final navigation = Wrap(
      spacing: desktop ? 34 : 18,
      runSpacing: 14,
      children: [
        for (var index = 0; index < links.length; index++)
          _FooterLink(
            index: index,
            label: links[index].label,
            onTap: () => context.read<AppScrollController>().scrollToSection(
              links[index].id,
            ),
          ),
      ],
    );
    final focus = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language
              .getText('footer.verification', defaultValue: 'Current focus')
              .toUpperCase(),
          style: AppFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.background.withValues(alpha: 0.62),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          language.getText(
            'cv_data.personal_info.tagline',
            defaultValue: 'Product-minded Flutter engineering',
          ),
          style: AppFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.background,
          ),
        ),
      ],
    );

    return desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 7, child: navigation),
              const SizedBox(width: 60),
              Expanded(flex: 3, child: focus),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [navigation, const SizedBox(height: 36), focus],
          );
  }
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.index,
    required this.label,
    required this.onTap,
  });

  final int index;
  final String label;
  final VoidCallback onTap;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: widget.onTap,
    onHoverChanged: (value) => setState(() => _hovered = value),
    focusColor: AppColors.background,
    semanticLabel: widget.label,
    child: AnimatedContainer(
      duration: AppDurations.fast,
      padding: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _hovered ? AppColors.background : Colors.transparent,
          ),
        ),
      ),
      child: Text(
        '${(widget.index + 1).toString().padLeft(2, '0')}  ${widget.label.toUpperCase()}',
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.background,
          letterSpacing: 0.85,
        ),
      ),
    ),
  );
}

class _FooterBottom extends StatelessWidget {
  const _FooterBottom({required this.name, required this.language});

  final String name;
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) {
    final shortcut = defaultTargetPlatform == TargetPlatform.macOS
        ? '\u2318K'
        : 'CTRL+K';
    return Container(
      padding: const EdgeInsets.only(top: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x3D0B0B0D))),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '\u00A9 ${DateTime.now().year} ${name.toUpperCase()}',
            style: _bottomStyle(),
          ),
          Text('FLUTTER / DART WASM / SKWASM', style: _bottomStyle()),
          CinematicFocusable(
            onTap: () => CommandPalette.show(context),
            semanticLabel:
                '${language.getText('footer.command_hint_prefix', defaultValue: 'Press')} $shortcut ${language.getText('footer.command_hint_suffix', defaultValue: 'to open command palette')}',
            focusColor: AppColors.background,
            child: Text('$shortcut / COMMAND', style: _bottomStyle()),
          ),
        ],
      ),
    );
  }

  TextStyle _bottomStyle() => AppFonts.jetBrainsMono(
    fontSize: 8,
    fontWeight: FontWeight.w600,
    color: AppColors.background.withValues(alpha: 0.62),
    letterSpacing: 0.75,
  );
}
