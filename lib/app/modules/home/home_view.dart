import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/blog_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/contact/contact_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/testimonials_section.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/footer.dart';
import 'package:flutter_web_portfolio/app/widgets/matrix_rain.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cinematic_background.dart';
import 'package:flutter_web_portfolio/app/widgets/constellation_particles.dart';
import 'package:flutter_web_portfolio/app/widgets/social_sidebar.dart';

/// Aurora Cinema home view — cinematic scene-driven portfolio.
/// Layer stack: dark base -> mesh gradient -> constellation particles -> content.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  /// Konami code sequence: Up Up Down Down Left Right Left Right B A
  static const _konamiSequence = <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyB,
    LogicalKeyboardKey.keyA,
  ];

  final List<LogicalKeyboardKey> _konamiBuffer = [];
  bool _showMatrixRain = false;
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

    // Konami code detection
    _konamiBuffer.add(event.logicalKey);
    if (_konamiBuffer.length > _konamiSequence.length) {
      _konamiBuffer.removeAt(0);
    }
    if (_konamiBuffer.length == _konamiSequence.length &&
        _isKonamiMatch()) {
      _konamiBuffer.clear();
      setState(() => _showMatrixRain = true);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _isKonamiMatch() {
    for (var i = 0; i < _konamiSequence.length; i++) {
      if (_konamiBuffer[i] != _konamiSequence[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = Get.find<AppScrollController>();
    final languageController = Get.find<LanguageController>();

    // After first frame: recalculate scene + handle deep-link scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<SceneDirector>()) {
        Get.find<SceneDirector>().recalculate();
      }
      scrollController.handleInitialDeepLink();
    });

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Obx(() {
        // Touch reactive values so Obx rebuilds on language/theme switch
        languageController.currentLanguage;
        final isDark = Get.isRegistered<ThemeController>()
            ? Get.find<ThemeController>().isDarkMode.value
            : true;

        return Scaffold(
          backgroundColor: isDark ? AppColors.background : AppColors.lightBackground,
          body: Stack(
            children: [
              if (isDark) ...[
                // Layer 1: Cinematic gradient mesh (parallax 0.3x)
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: scrollController.scrollController,
                    builder: (_, child) {
                      final offset = scrollController
                              .scrollController.hasClients
                          ? scrollController.scrollController.offset
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset * 0.3),
                        child: child,
                      );
                    },
                    child: const CinematicBackground(),
                  ),
                ),
                // Layer 2: Constellation particles (parallax 0.15x)
                Positioned.fill(
                  child: ListenableBuilder(
                    listenable: scrollController.scrollController,
                    builder: (_, child) {
                      final offset = scrollController
                              .scrollController.hasClients
                          ? scrollController.scrollController.offset
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset * 0.15),
                        child: child,
                      );
                    },
                    child: const ConstellationParticles(particleCount: 100),
                  ),
                ),
              ] else
                // Light mode: subtle gradient background
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.lightBackground,
                          AppColors.lightBackgroundDark,
                          AppColors.lightBackground,
                        ],
                      ),
                    ),
                  ),
                ),
              // Skip-to-content link (accessibility)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _SkipToContentLink(
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
              // Layer 3: Scrollable content
              ValueListenableBuilder<bool>(
                valueListenable: HomeSection.entranceComplete,
                builder: (context, entranceDone, child) => CustomScrollView(
                  controller: scrollController.scrollController,
                  physics: entranceDone
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  slivers: [
                    CustomSliverAppBar(
                      scrollController: scrollController,
                      languageController: languageController,
                    ),
                    _buildSection(
                      scrollController.homeKey,
                      const HomeSection(),
                      context,
                      animated: false,
                    ),
                    _buildSection(
                      scrollController.aboutKey,
                      const AboutSection(),
                      context,
                    ),
                    _buildSection(
                      scrollController.experienceKey,
                      const ExperienceSection(),
                      context,
                      delay: AppDurations.staggerShort,
                    ),
                    _buildSection(
                      scrollController.testimonialsKey,
                      const TestimonialsSection(),
                      context,
                      delay: AppDurations.staggerShort,
                    ),
                    _buildSection(
                      scrollController.blogKey,
                      const BlogSection(),
                      context,
                      delay: AppDurations.staggerShort,
                    ),
                    _buildSection(
                      scrollController.projectsKey,
                      const ProjectsSection(),
                      context,
                      delay: AppDurations.staggerShort,
                    ),
                    _buildSection(
                      scrollController.contactKey,
                      const ContactSection(),
                      context,
                      delay: AppDurations.staggerShort,
                    ),
                    const SliverToBoxAdapter(child: PortfolioFooter()),
                  ],
                ),
              ),
              // Layer 4: Fixed social sidebars (desktop only)
              ValueListenableBuilder<bool>(
                valueListenable: HomeSection.entranceComplete,
                builder: (context, entranceDone, _) => Positioned(
                  left: 40,
                  bottom: 0,
                  child: SocialSidebarLeft(visible: entranceDone),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: HomeSection.entranceComplete,
                builder: (context, entranceDone, _) => Positioned(
                  right: 40,
                  bottom: 0,
                  child: SocialSidebarRight(visible: entranceDone),
                ),
              ),
              // Layer 5: Back-to-top button
              const BackToTopButton(),
              // Layer 5: Matrix rain easter egg overlay
              if (_showMatrixRain)
                Positioned.fill(
                  child: MatrixRain(
                    onDismiss: () => setState(() => _showMatrixRain = false),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  EdgeInsets _sectionPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : (width > 900 ? AppDimensions.sectionPaddingTablet : AppDimensions.sectionPaddingMobile); // TODO: use Breakpoints.tablet instead of 900
    return EdgeInsets.symmetric(vertical: 80, horizontal: horizontal);
  }

  SliverToBoxAdapter _buildSection(
    GlobalKey key,
    Widget child,
    BuildContext context, {
    bool animated = true,
    Duration delay = Duration.zero,
  }) => SliverToBoxAdapter(
    child: Container(
      key: key,
      padding: _sectionPadding(context),
      child: animated
          ? ScrollFadeIn(delay: delay, child: child)
          : child,
    ),
  );
}

/// Hidden skip-to-content link for keyboard and screen reader users.
///
/// Invisible by default; becomes visible when focused via Tab key.
class _SkipToContentLink extends StatelessWidget {
  const _SkipToContentLink({
    required this.visible,
    required this.focusNode,
    required this.onFocusChanged,
    required this.onActivate,
  });

  final bool visible;
  final FocusNode focusNode;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Skip to content',
    button: true,
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
          transform: Matrix4.translationValues(
            0,
            visible ? 0 : -48,
            0,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Skip to content',
                style: TextStyle(
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
  );
}
