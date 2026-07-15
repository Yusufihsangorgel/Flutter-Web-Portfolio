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

/// First-frame portfolio introduction.
///
/// The hero deliberately renders at its final opacity. The small HTML shell
/// shown while Flutter Wasm starts mirrors this composition and fades directly
/// into it, so visitors see one continuous opening instead of two splash
/// sequences.
class HomeSection extends StatelessWidget {
  const HomeSection({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    builder: (context, _) {
      final language = context.read<LanguageCubit>();
      final size = MediaQuery.sizeOf(context);
      final isDesktop = size.width >= Breakpoints.desktop;
      final horizontalPadding = size.width > AppDimensions.maxContentWidth
          ? AppDimensions.sectionPaddingDesktop
          : size.width > Breakpoints.tablet
          ? AppDimensions.sectionPaddingTablet
          : AppDimensions.sectionPaddingMobile;
      final viewportHeight =
          size.height -
          (size.width < Breakpoints.tablet
              ? AppDimensions.appBarHeightMobile
              : AppDimensions.appBarHeight);

      return SizedBox(
        width: double.infinity,
        height: viewportHeight.clamp(680.0, 960.0),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: _HeroCopy(
                                language: language,
                                availableWidth: 650,
                              ),
                            ),
                            const SizedBox(width: 52),
                            const Expanded(
                              flex: 4,
                              child: _PlatformComposition(),
                            ),
                          ],
                        )
                      : _HeroCopy(
                          language: language,
                          availableWidth: size.width - horizontalPadding * 2,
                        ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: ScrollIndicator(delay: Duration.zero),
            ),
          ],
        ),
      );
    },
  );
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.language, required this.availableWidth});

  final LanguageCubit language;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < Breakpoints.tablet
        ? (width * 0.112).clamp(40.0, 56.0)
        : (availableWidth * 0.12).clamp(66.0, 88.0);
    final title = language
        .getText('home_section.title', defaultValue: 'SENIOR FLUTTER ENGINEER.')
        .toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 28, height: 1, color: AppColors.heroAccent),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                language.getText(
                  'cv_data.personal_info.tagline',
                  defaultValue: 'Product-minded Flutter engineering',
                ),
                style: AppFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heroAccent,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Semantics(
          header: true,
          headingLevel: 1,
          label: title,
          excludeSemantics: true,
          child: ExcludeSemantics(
            child: Text(
              title,
              style: AppFonts.spaceGrotesk(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                color: AppColors.textBright,
                height: 0.94,
                letterSpacing: width < Breakpoints.tablet ? -2.0 : -3.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 610),
          child: Text(
            language.getText(
              'home_section.subtitle',
              defaultValue:
                  'Building useful products across mobile, desktop, and web.',
            ),
            style: AppFonts.spaceGrotesk(
              fontSize: width < Breakpoints.tablet ? 19 : 24,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              height: 1.45,
              letterSpacing: -0.25,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          language.getText(
            'cv_data.personal_info.location',
            defaultValue: 'Remote',
          ),
          style: AppFonts.jetBrainsMono(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 38),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            CinematicButton(
              label: language.getText(
                'home_section.view_work',
                defaultValue: 'View selected work',
              ),
              isPrimary: true,
              onTap: () => context.read<AppScrollController>().scrollToSection(
                'projects',
              ),
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
}

/// A code-native cross-platform composition. It is intentionally made from
/// ordinary Flutter layout primitives rather than an exported illustration.
class _PlatformComposition extends StatelessWidget {
  const _PlatformComposition();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Flutter interface previews for mobile, desktop, and web',
    image: true,
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 0.92,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.heroAccent.withValues(alpha: 0.16),
            ),
            gradient: RadialGradient(
              center: const Alignment(0.15, -0.1),
              radius: 1.1,
              colors: [
                AppColors.heroAccent.withValues(alpha: 0.1),
                AppColors.backgroundLight.withValues(alpha: 0.34),
                Colors.transparent,
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                top: 52,
                left: 44,
                right: 22,
                child: _DesktopPreview(),
              ),
              const Positioned(left: 22, bottom: 26, child: _PhonePreview()),
              Positioned(
                right: 28,
                bottom: 40,
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0920).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PreviewLabel('SHARED PRODUCT LAYER'),
                      SizedBox(height: 14),
                      _SignalRow(width: 122, color: AppColors.heroAccent),
                      SizedBox(height: 9),
                      _SignalRow(width: 94, color: Color(0xFF8B5CF6)),
                      SizedBox(height: 9),
                      _SignalRow(width: 140, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 24,
                child: Text(
                  'FLUTTER / DART',
                  style: AppFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heroAccent,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DesktopPreview extends StatelessWidget {
  const _DesktopPreview();

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    decoration: BoxDecoration(
      color: const Color(0xFF08071C),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 36,
          offset: Offset(0, 20),
        ),
      ],
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              for (final color in const [
                Color(0xFFF43F5E),
                Color(0xFFF59E0B),
                Color(0xFF10B981),
              ]) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              const _PreviewLabel('DESKTOP / WEB'),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SignalRow(width: 112, color: AppColors.heroAccent),
                      const SizedBox(height: 12),
                      Container(
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.035),
                        ),
                      ),
                      const Spacer(),
                      const _SignalRow(width: 82, color: Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                for (final height in const [42.0, 72.0, 54.0, 96.0, 78.0])
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Container(
                      width: 12,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF0891B2), Color(0xFF8B5CF6)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview();

  @override
  Widget build(BuildContext context) => Container(
    width: 118,
    height: 226,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFF050412),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x77000000),
          blurRadius: 30,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12263A), Color(0xFF11102A)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.heroAccent, Color(0xFF8B5CF6)],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _SignalRow(width: 62, color: AppColors.textBright),
            const SizedBox(height: 9),
            _SignalRow(
              width: 44,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final color in const [
                  Color(0xFFF43F5E),
                  Color(0xFF10B981),
                ])
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 5,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppFonts.jetBrainsMono(
      fontSize: 8,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 1.1,
    ),
  );
}
