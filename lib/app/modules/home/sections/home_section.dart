import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_indicator.dart';

/// Editorial opening for the Render Atlas.
///
/// Typography is the principal visual object; the procedural scene behind it
/// supplies depth without turning the portfolio into a product mock-up.
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) {
          final language = context.read<LanguageCubit>();
          final size = MediaQuery.sizeOf(context);
          final desktop = size.width >= Breakpoints.desktop;
          final tablet = size.width >= Breakpoints.tablet;
          final horizontal = size.width > AppDimensions.maxContentWidth
              ? AppDimensions.sectionPaddingDesktop
              : tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile;
          final appBarHeight = tablet
              ? AppDimensions.appBarHeight
              : AppDimensions.appBarHeightMobile;
          final height = (size.height - appBarHeight).clamp(720.0, 1040.0);

          return SizedBox(
            width: double.infinity,
            height: height,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 0),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _HeroDataRail(language: language, desktop: tablet),
                  ),
                  Positioned.fill(
                    top: tablet ? 72 : 58,
                    bottom: desktop ? 170 : 224,
                    child: Align(
                      alignment: desktop
                          ? const Alignment(0, -0.08)
                          : Alignment.center,
                      child: _EditorialTitle(language: language),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 66,
                    child: desktop
                        ? _DesktopHeroFooter(language: language)
                        : _MobileHeroFooter(language: language),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: ScrollIndicator(delay: Duration.zero),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _HeroDataRail extends StatelessWidget {
  const _HeroDataRail({required this.language, required this.desktop});

  final LanguageCubit language;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final location = language.getText(
      'cv_data.personal_info.location',
      defaultValue: 'Remote',
    );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.only(bottom: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
        ),
        child: Row(
          children: [
            const _RailLabel(value: '00 / RENDER ATLAS'),
            const Spacer(),
            if (desktop) ...[
              const _RailLabel(value: 'FLUTTER / DART / GO'),
              const SizedBox(width: 52),
            ],
            _RailLabel(value: location.toUpperCase()),
            const SizedBox(width: 18),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.signalLime,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  const _RailLabel({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    style: AppFonts.jetBrainsMono(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 1.25,
    ),
  );
}

class _EditorialTitle extends StatelessWidget {
  const _EditorialTitle({required this.language});
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final title = language
        .getText('home_section.title', defaultValue: 'SENIOR FLUTTER ENGINEER.')
        .trim()
        .toUpperCase();
    final words = title.split(RegExp(r'\s+'));
    final lastWord = words.isEmpty ? title : words.last;
    final prefix = words.length > 1
        ? words.take(words.length - 1).join(' ')
        : '';
    final titleSize = width < Breakpoints.tablet
        ? (width * 0.135).clamp(47.0, 70.0)
        : width < Breakpoints.desktop
        ? (width * 0.092).clamp(74.0, 98.0)
        : (width * 0.087).clamp(104.0, 154.0);

    return Semantics(
      header: true,
      headingLevel: 1,
      label: title,
      excludeSemantics: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (prefix.isNotEmpty)
              Text(
                prefix,
                maxLines: 2,
                style: AppFonts.spaceGrotesk(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBright,
                  height: 0.78,
                  letterSpacing: -titleSize * 0.055,
                ),
              ),
            Transform.translate(
              offset: Offset(0, -titleSize * 0.035),
              child: Align(
                alignment: width >= Breakpoints.tablet
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  lastWord,
                  maxLines: 1,
                  style: AppFonts.instrumentSerif(
                    fontSize: titleSize * 1.07,
                    fontStyle: FontStyle.italic,
                    color: AppColors.heroAccent,
                    height: 0.82,
                    letterSpacing: -titleSize * 0.035,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeroFooter extends StatelessWidget {
  const _DesktopHeroFooter({required this.language});
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(flex: 5, child: _HeroStatement(language: language)),
      const SizedBox(width: 80),
      Expanded(flex: 4, child: _CapabilityIndex(language: language)),
    ],
  );
}

class _MobileHeroFooter extends StatelessWidget {
  const _MobileHeroFooter({required this.language});
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _HeroStatement(language: language),
      const SizedBox(height: 24),
      _CapabilityIndex(language: language, compact: true),
    ],
  );
}

class _HeroStatement extends StatelessWidget {
  const _HeroStatement({required this.language});
  final LanguageCubit language;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Text(
          language.getText(
            'home_section.subtitle',
            defaultValue:
                'Building useful products across mobile, desktop, and web.',
          ),
          style: AppFonts.spaceGrotesk(
            fontSize: MediaQuery.sizeOf(context).width < Breakpoints.tablet
                ? 18
                : 22,
            fontWeight: FontWeight.w500,
            color: AppColors.textBright,
            height: 1.35,
            letterSpacing: -0.35,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          CinematicButton(
            label: language.getText(
              'home_section.view_work',
              defaultValue: 'View selected work',
            ),
            isPrimary: true,
            onTap: () =>
                context.read<AppScrollController>().scrollToSection('projects'),
          ),
          CinematicButton(
            label: language.getText(
              'home_section.inspect_runtime',
              defaultValue: 'About me',
            ),
            onTap: () =>
                context.read<AppScrollController>().scrollToSection('about'),
          ),
        ],
      ),
    ],
  );
}

class _CapabilityIndex extends StatelessWidget {
  const _CapabilityIndex({required this.language, this.compact = false});
  final LanguageCubit language;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final personal = language.cvData['personal_info'] as Map<String, dynamic>?;
    final values = (personal?['subtitles'] as List? ?? const [])
        .whereType<String>()
        .take(3)
        .toList();
    return ExcludeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < values.length; index++) ...[
            if (index > 0) SizedBox(width: compact ? 16 : 28),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 9),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x3DF2F0E9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: AppFonts.jetBrainsMono(
                        fontSize: 8,
                        color: AppColors.heroAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      values[index].toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.jetBrainsMono(
                        fontSize: compact ? 8 : 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.45,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
