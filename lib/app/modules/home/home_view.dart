import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/premium_footer.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cinematic_background.dart';

/// Single-document portfolio with chapter-aware background transitions.
/// Layer stack: procedural Render Atlas and one semantic content document.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _skipLinkFocusNode = FocusNode();
  bool _skipLinkVisible = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _skipLinkFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Ctrl+K / Cmd+K -> open command palette
    if (event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      CommandPalette.show(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = context.read<AppScrollController>();
    final languageController = BlocProvider.of<LanguageCubit>(context);
    scrollController.setReduceMotion(MediaQuery.disableAnimationsOf(context));

    // After first frame: recalculate scene + handle deep-link scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.refreshSectionGeometry();
      context.read<SceneDirector>().recalculate();
      scrollController.handleInitialDeepLink();
    });

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          final active = context.read<PortfolioDocument>().activeSections;
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _buildBody(
              context,
              scrollController,
              languageController,
              active,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppScrollController scrollController,
    LanguageCubit languageController,
    List<String> active,
  ) {
    final story = context.read<PortfolioDocument>().story;
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: CinematicBackground()),
        ),
        // Skip-to-content link (accessibility)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _SkipToContentLink(
            label: languageController.getText(
              'accessibility.skip_to_content',
              defaultValue: 'Skip to content',
            ),
            visible: _skipLinkVisible,
            focusNode: _skipLinkFocusNode,
            onFocusChanged: (focused) {
              setState(() => _skipLinkVisible = focused);
            },
            onActivate: () {
              scrollController.scrollToSection('about');
            },
          ),
        ),
        // Layer 3: one continuous, immediately interactive document.
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: CustomScrollView(
            controller: scrollController.scrollController,
            physics: const ClampingScrollPhysics(),
            // This is a short, single-document portfolio. Keeping every chapter
            // mounted makes global navigation, measured scene transitions, and
            // the accessibility tree deterministic from the first frame.
            cacheExtent: 16000,
            slivers: [
              CustomSliverAppBar(
                scrollController: scrollController,
                languageController: languageController,
              ),
              _buildSection(
                scrollController.homeKey,
                const HomeSection(),
                context,
                isHero: true,
              ),
              if (active.contains('about')) ...[
                _NarrativeBridge(beat: story[0], from: 0, to: 1),
                _buildSection(
                  scrollController.aboutKey,
                  const AboutSection(),
                  context,
                ),
              ],
              if (active.contains('experience')) ...[
                _NarrativeBridge(beat: story[1], from: 1, to: 2),
                _buildSection(
                  scrollController.experienceKey,
                  const ExperienceSection(),
                  context,
                ),
              ],
              if (active.contains('proof')) ...[
                _NarrativeBridge(beat: story[2], from: 2, to: 3),
                _buildSection(
                  scrollController.proofKey,
                  const ProofSection(),
                  context,
                ),
              ],
              if (active.contains('projects')) ...[
                _NarrativeBridge(beat: story[3], from: 3, to: 4),
                _buildSection(
                  scrollController.projectsKey,
                  const ProjectsSection(),
                  context,
                ),
              ],
              const SliverToBoxAdapter(child: PremiumFooter()),
            ],
          ),
        ),
        // Layer 4: Back-to-top button with scroll progress
        const BackToTopButton(),
      ],
    );
  }

  EdgeInsets _sectionPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : (width > Breakpoints.tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile);
    final vertical = width > Breakpoints.tablet ? 96.0 : 58.0;
    return EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  }

  SliverToBoxAdapter _buildSection(
    GlobalKey key,
    Widget child,
    BuildContext context, {
    bool isHero = false,
  }) => SliverToBoxAdapter(
    child: Container(
      key: key,
      padding: isHero ? EdgeInsets.zero : _sectionPadding(context),
      child: child,
    ),
  );
}

class _NarrativeBridge extends StatelessWidget {
  const _NarrativeBridge({
    required this.beat,
    required this.from,
    required this.to,
  });

  final PortfolioStoryBeat beat;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : (width > Breakpoints.tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile);
    final fromColor = SceneConfigs.scenes[from].accent;
    final toColor = SceneConfigs.scenes[to].accent;

    final compact = width < Breakpoints.tablet;

    return SliverToBoxAdapter(
      child: Semantics(
        container: true,
        label: '${beat.eyebrow}. ${beat.title}. ${beat.body}',
        child: ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: SizedBox(
              height: compact ? 430 : 560,
              child: Stack(
                children: [
                  Positioned(
                    top: compact ? 44 : 72,
                    left: 0,
                    right: 0,
                    child: _BridgeRail(
                      beat: beat,
                      from: from,
                      to: to,
                      fromColor: fromColor,
                      toColor: toColor,
                    ),
                  ),
                  Positioned(
                    top: compact ? 108 : 142,
                    left: 0,
                    right: compact ? 0 : width * 0.12,
                    child: Text(
                      beat.title,
                      style: AppFonts.instrumentSerif(
                        fontSize: compact ? 49 : 82,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textBright,
                        height: 0.98,
                        letterSpacing: compact ? -1.2 : -2.6,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: compact ? 42 : 68,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? width - horizontal * 2 : 520,
                      ),
                      child: Text(
                        beat.body,
                        style: AppFonts.spaceGrotesk(
                          fontSize: compact ? 16 : 19,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          height: 1.55,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BridgeRail extends StatelessWidget {
  const _BridgeRail({
    required this.beat,
    required this.from,
    required this.to,
    required this.fromColor,
    required this.toColor,
  });

  final PortfolioStoryBeat beat;
  final int from;
  final int to;
  final Color fromColor;
  final Color toColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ChapterIndex(value: from, color: fromColor),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                fromColor.withValues(alpha: 0.24),
                fromColor.withValues(alpha: 0.9),
                toColor.withValues(alpha: 0.9),
                toColor.withValues(alpha: 0.24),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 18),
      Text(
        beat.eyebrow.toUpperCase(),
        style: AppFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: toColor,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(width: 18),
      _ChapterIndex(value: to, color: toColor),
    ],
  );
}

class _ChapterIndex extends StatelessWidget {
  const _ChapterIndex({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    value.toString().padLeft(2, '0'),
    style: AppFonts.jetBrainsMono(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 1.4,
    ),
  );
}

/// Hidden skip-to-content link for keyboard and screen reader users.
///
/// Invisible by default; becomes visible when focused via Tab key.
class _SkipToContentLink extends StatelessWidget {
  const _SkipToContentLink({
    required this.label,
    required this.visible,
    required this.focusNode,
    required this.onFocusChanged,
    required this.onActivate,
  });

  final String label;
  final bool visible;
  final FocusNode focusNode;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    focusable: true,
    onTap: onActivate,
    excludeSemantics: true,
    child: ExcludeSemantics(
      child: Focus(
        focusNode: focusNode,
        onFocusChange: onFocusChanged,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            onActivate();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: AppDurations.fast,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            transform: Matrix4.translationValues(0, visible ? 0 : -48, 0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
