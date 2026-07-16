import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/premium_footer.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_chapter_handoff.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cinematic_background.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

/// A single, semantic portfolio document with measured section navigation.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _skipLinkFocusNode = FocusNode();
  bool _skipLinkVisible = false;
  AppScrollController? _scheduledScrollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollController = context.read<AppScrollController>();
    if (identical(scrollController, _scheduledScrollController)) return;
    _scheduledScrollController = scrollController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !identical(scrollController, _scheduledScrollController)) {
        return;
      }
      scrollController
        ..refreshSectionGeometry()
        ..handleInitialDeepLink();
    });
  }

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
    scrollController.setReduceMotion(prefersReducedMotion(context));

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          final narrative = context.read<NarrativeDocument>();
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _buildBody(
              context,
              scrollController,
              languageController,
              narrative,
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
    NarrativeDocument narrative,
  ) => Stack(
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
            final firstContentChapter = narrative.chapters.firstWhere(
              (chapter) => !chapter.id.isHome,
              orElse: () => narrative.chapters.first,
            );
            scrollController.scrollToSection(firstContentChapter.id.value);
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
          slivers: [
            CustomSliverAppBar(
              scrollController: scrollController,
              languageController: languageController,
            ),
            // One document box deliberately lays out this short portfolio as
            // a whole. Every chapter therefore has measured geometry for
            // deep links and keyboard navigation without a giant cacheExtent.
            SliverToBoxAdapter(
              child: NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (_) {
                  scrollController.markGeometryDirty();
                  return false;
                },
                child: SizeChangedLayoutNotifier(
                  child: Column(
                    children: [
                      ..._buildChapters(context, scrollController, narrative),
                      const PremiumFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Layer 4: Back-to-top button with scroll progress
      const BackToTopButton(),
    ],
  );

  List<Widget> _buildChapters(
    BuildContext context,
    AppScrollController scrollController,
    NarrativeDocument narrative,
  ) {
    final chapters = <Widget>[];
    for (var index = 0; index < narrative.chapters.length; index += 1) {
      final chapter = narrative.chapters[index];
      final isLast = index == narrative.chapters.length - 1;
      chapters.add(
        _buildSection(
          scrollController.keyFor(chapter.id),
          _widgetFor(chapter.id),
          context,
          isHero: chapter.id.isHome,
          fullBleed: chapter.id == SectionId.projects,
          isLast: isLast,
        ),
      );
      if (!isLast) {
        final nextChapter = narrative.chapters[index + 1];
        final language = context.read<LanguageCubit>();
        chapters.add(
          NarrativeChapterHandoff(
            from: chapter,
            to: nextChapter,
            position: scrollController.narrativePosition,
            chapterNumber: narrative.sectionNumber(nextChapter.id),
            label: language.getText(
              'nav.${nextChapter.id.value}',
              defaultValue: nextChapter.id.value,
            ),
          ),
        );
      }
    }
    return chapters;
  }

  EdgeInsets _sectionPadding(BuildContext context, {required bool isLast}) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width > AppDimensions.maxContentWidth
        ? AppDimensions.sectionPaddingDesktop
        : (width >= Breakpoints.tablet
              ? AppDimensions.sectionPaddingTablet
              : AppDimensions.sectionPaddingMobile);
    final top = width >= Breakpoints.tablet ? 80.0 : 44.0;
    final bottom = isLast ? (width >= Breakpoints.tablet ? 96.0 : 58.0) : 0.0;
    final right = width < Breakpoints.mobile
        ? horizontal + 44
        : (width < Breakpoints.tablet ? horizontal + 24 : horizontal);
    return EdgeInsets.fromLTRB(horizontal, top, right, bottom);
  }

  Widget _buildSection(
    GlobalKey key,
    Widget child,
    BuildContext context, {
    bool isHero = false,
    bool fullBleed = false,
    bool isLast = false,
  }) => Container(
    key: key,
    padding: isHero || fullBleed
        ? EdgeInsets.zero
        : _sectionPadding(context, isLast: isLast),
    child: child,
  );

  Widget _widgetFor(SectionId sectionId) => switch (sectionId.value) {
    'home' => const HomeSection(),
    'about' => const AboutSection(),
    'experience' => const ExperienceSection(),
    'proof' => const ProofSection(),
    'projects' => const ProjectsSection(),
    final value => throw StateError(
      'No section widget is registered for narrative chapter "$value".',
    ),
  };
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
