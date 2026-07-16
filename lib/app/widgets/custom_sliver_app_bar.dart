import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_config.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/fullscreen_menu.dart';
import 'package:flutter_web_portfolio/app/widgets/language_switcher.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';
import 'package:flutter_web_portfolio/app/narrative/application/narrative_position.dart';

/// Compact navigation for the single-page document.
/// Shrinks from 80px to 60px as the user scrolls down (200px threshold).
class CustomSliverAppBar extends StatefulWidget {
  const CustomSliverAppBar({
    super.key,
    required this.languageController,
    required this.scrollController,
    this.actions,
  });

  final LanguageCubit languageController;
  final AppScrollController scrollController;
  final List<Widget>? actions;

  /// Nav sections derived at build-time from active sections (excludes 'home').
  static List<String> navSections(AppScrollController scrollController) =>
      scrollController.sectionIds
          .where((section) => section != 'home')
          .toList(growable: false);

  @override
  State<CustomSliverAppBar> createState() => _CustomSliverAppBarState();
}

class _CustomSliverAppBarState extends State<CustomSliverAppBar> {
  double _toolbarHeight = AppDimensions.appBarHeight;

  /// Scale factor for logo and nav items: 1.0 at top, smaller when collapsed.
  double get _scaleFactor => _toolbarHeight / AppDimensions.appBarHeight;

  @override
  void initState() {
    super.initState();
    widget.scrollController.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController.scrollController;
    if (!controller.hasClients) return;

    final newHeight = AppDimensions.appBarHeightForScrollOffset(
      controller.offset,
    );

    if ((newHeight - _toolbarHeight).abs() > 0.5) {
      setState(() => _toolbarHeight = newHeight);
      widget.scrollController.markGeometryDirty(preserveReadingAnchor: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;

    return SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      toolbarHeight: _toolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      excludeHeaderSemantics: true,
      flexibleSpace: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                // Pinned chapter navigation is deliberately opaque. Long
                // interlude headlines must never ghost through the toolbar
                // while anchor navigation settles.
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: Color(0x2412110F), width: 1),
                ),
              ),
            ),
          ),
          _SceneProgressBar(scrollController: widget.scrollController),
        ],
      ),
      title: _LogoText(
        onTap: () => widget.scrollController.scrollToSection('home'),
        scaleFactor: _scaleFactor,
        languageController: widget.languageController,
        semanticLabel: widget.languageController.getText(
          'accessibility.back_to_top',
          defaultValue: 'Back to top',
        ),
      ),
      leading: isMobile
          ? IconButton(
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 24 * _scaleFactor,
              ),
              onPressed: () => FullscreenMenu.show(context),
            )
          : null,
      actions: [
        if (!isMobile) _buildNavItems(),
        const LanguageSwitcher(),
        ...?widget.actions,
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNavItems() => BlocBuilder<LanguageCubit, LanguageState>(
    buildWhen: (previous, current) =>
        previous.languageCode != current.languageCode ||
        !identical(previous.translations, current.translations),
    builder: (context, languageState) =>
        BlocBuilder<AppScrollController, AppScrollState>(
          buildWhen: (previous, current) =>
              previous.activeSection != current.activeSection,
          builder: (context, scrollState) {
            final sections = CustomSliverAppBar.navSections(
              widget.scrollController,
            );
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final section in sections)
                  _NavItem(
                    label: widget.languageController.getText(
                      'nav.$section',
                      defaultValue: section.toUpperCase(),
                    ),
                    isActive: scrollState.activeSection == section,
                    onTap: () =>
                        widget.scrollController.scrollToSection(section),
                    scaleFactor: _scaleFactor,
                  ),
              ],
            );
          },
        ),
  );
}

// ---------------------------------------------------------------------------
// Personal wordmark derived from canonical profile data.
// ---------------------------------------------------------------------------
class _LogoText extends StatefulWidget {
  const _LogoText({
    required this.onTap,
    this.scaleFactor = 1.0,
    required this.languageController,
    required this.semanticLabel,
  });
  final VoidCallback onTap;
  final double scaleFactor;
  final LanguageCubit languageController;
  final String semanticLabel;

  @override
  State<_LogoText> createState() => _LogoTextState();
}

class _LogoTextState extends State<_LogoText> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textBright;
    const hoverColor = AppColors.heroAccent;

    return CinematicFocusable(
      onTap: widget.onTap,
      onHoverChanged: (h) => setState(() => _hovered = h),
      semanticLabel: widget.semanticLabel,
      child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        child: Text(
          AppConfig.navigationName(context.read<PortfolioDocument>()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.spaceGrotesk(
            fontSize: 13 * widget.scaleFactor,
            fontWeight: FontWeight.w600,
            color: _hovered ? hoverColor : baseColor,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav item: readable case with a restrained active underline.
// ---------------------------------------------------------------------------
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.scaleFactor = 1.0,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final double scaleFactor;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.textBright;
    const inactiveColor = AppColors.textPrimary;
    const underlineColor = AppColors.heroAccent;

    return CinematicFocusable(
      onTap: widget.onTap,
      onHoverChanged: (h) => setState(() => _hovered = h),
      semanticLabel: widget.label,
      selected: widget.isActive,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: AppFonts.spaceGrotesk(
                fontSize: 12 * widget.scaleFactor,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                color: widget.isActive
                    ? activeColor
                    : (_hovered ? activeColor : inactiveColor),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            // Underline — animates from left
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: AppDurations.buttonHover,
                curve: CinematicCurves.hoverLift,
                width: widget.isActive || _hovered ? 20 : 0,
                height: 1,
                color: underlineColor.withValues(
                  alpha: widget.isActive ? 0.6 : 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scene-aware scroll progress bar (1px, gradient with scene accent)
// ---------------------------------------------------------------------------
class _SceneProgressBar extends StatelessWidget {
  const _SceneProgressBar({required this.scrollController});
  final AppScrollController scrollController;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: SceneAccentBuilder(
      builder: (context, accent) => RepaintBoundary(
        child: CustomPaint(
          painter: _SceneProgressPainter(
            narrativePosition: scrollController.narrativePosition,
            accent: accent,
            textDirection: Directionality.of(context),
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

final class _SceneProgressPainter extends CustomPainter {
  _SceneProgressPainter({
    required this.narrativePosition,
    required this.accent,
    required this.textDirection,
  }) : super(repaint: narrativePosition);

  final ValueListenable<NarrativePosition> narrativePosition;
  final Color accent;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final progress = narrativePosition.value.documentProgress.clamp(0.0, 1.0);
    final bounds = SceneProgressGeometry.bounds(
      size: size,
      progress: progress,
      textDirection: textDirection,
    );
    if (bounds.isEmpty) return;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          colors: [accent.withValues(alpha: 0.2), accent],
          begin: textDirection == TextDirection.ltr
              ? Alignment.centerLeft
              : Alignment.centerRight,
          end: textDirection == TextDirection.ltr
              ? Alignment.centerRight
              : Alignment.centerLeft,
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_SceneProgressPainter oldDelegate) =>
      !identical(narrativePosition, oldDelegate.narrativePosition) ||
      accent != oldDelegate.accent ||
      textDirection != oldDelegate.textDirection;
}

/// Physical bounds of the reading-progress fill in either writing direction.
abstract final class SceneProgressGeometry {
  static Rect bounds({
    required Size size,
    required double progress,
    required TextDirection textDirection,
  }) {
    final width = size.width * progress.clamp(0.0, 1.0);
    final left = textDirection == TextDirection.ltr ? 0.0 : size.width - width;
    return Rect.fromLTWH(left, 0, width, size.height);
  }
}
