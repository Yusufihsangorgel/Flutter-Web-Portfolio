import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/packages/packages_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/proof_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/writing/writing_section.dart';
import 'package:flutter_web_portfolio/app/widgets/back_to_top_button.dart';
import 'package:flutter_web_portfolio/app/widgets/command_palette.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/portfolio_footer.dart';
import 'package:flutter_web_portfolio/app/widgets/skip_to_content_link.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_chapter_handoff.dart';
import 'package:flutter_web_portfolio/app/widgets/narrative_stage.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/widgets/background/narrative_background.dart';
import 'package:flutter_web_portfolio/app/narrative/domain/narrative_document.dart';

/// A single, semantic portfolio document with measured section navigation.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final FocusNode _focusNode = FocusNode(skipTraversal: true);
  final FocusNode _skipLinkFocusNode = FocusNode();
  final FocusNode _mainContentFocusNode = FocusNode(
    debugLabel: 'portfolio-main-content',
    skipTraversal: true,
  );
  String? _lastAnnouncedLanguageWarning;
  AppScrollController? _scheduledScrollController;
  VoidCallback? _endSkipWait;

  static final _skipScrollBound = AppDurations.sectionScroll * 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollController = context.read<AppScrollController>();
    final languageState = context.read<LanguageCubit>().state;
    final languageWarning = languageState.errorMessage;
    if (languageState.status == LanguageStatus.ready &&
        languageWarning != null) {
      _announceLanguageWarning(languageWarning);
    }
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
    _endSkipWait?.call();
    _focusNode.dispose();
    _skipLinkFocusNode.dispose();
    _mainContentFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      CommandPalette.show(context);
      return KeyEventResult.handled;
    }

    // The page holds the initial focus; the first Tab enters at the skip link.
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        !HardwareKeyboard.instance.isShiftPressed &&
        _focusNode.hasPrimaryFocus) {
      _skipLinkFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _announceLanguageWarning(String message) {
    if (message.isEmpty || message == _lastAnnouncedLanguageWarning) return;
    _lastAnnouncedLanguageWarning = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              label: message,
              excludeSemantics: true,
              child: Text(message),
            ),
          ),
        );
    });
  }

  Future<void> _skipToContent() async {
    if (_endSkipWait != null) return;
    final controller = context.read<AppScrollController>();
    controller.scrollToSection(_mainContentId(controller.narrative).value);
    if (controller.scrollController.hasClients) {
      await _waitForScrollEnd(controller.scrollController.position);
    }
    if (mounted && _isFocusUnclaimed()) _mainContentFocusNode.requestFocus();
  }

  // Ends on scroll stop or interruption, on unmount, or at the time bound.
  Future<void> _waitForScrollEnd(ScrollPosition position) {
    final scrolling = position.isScrollingNotifier;
    if (!scrolling.value) return Future<void>.value();
    final ended = Completer<void>();
    late final Timer bound;
    late final VoidCallback onScrollChanged;
    void end() {
      if (ended.isCompleted) return;
      _endSkipWait = null;
      bound.cancel();
      scrolling.removeListener(onScrollChanged);
      ended.complete();
    }

    onScrollChanged = () {
      if (!scrolling.value) end();
    };
    bound = Timer(_skipScrollBound, end);
    scrolling.addListener(onScrollChanged);
    _endSkipWait = end;
    return ended.future;
  }

  // Skip focus yields to any control the reader chose in the meantime.
  bool _isFocusUnclaimed() {
    final focus = FocusManager.instance.primaryFocus;
    return focus == null ||
        focus == _skipLinkFocusNode ||
        focus == _focusNode ||
        focus is FocusScopeNode;
  }

  static SectionId _mainContentId(NarrativeDocument narrative) => narrative
      .chapters
      .firstWhere(
        (chapter) => !chapter.id.isHome,
        orElse: () => narrative.chapters.first,
      )
      .id;

  @override
  Widget build(BuildContext context) {
    final scrollController = context.read<AppScrollController>();
    final languageController = BlocProvider.of<LanguageCubit>(context);
    scrollController.setReduceMotion(prefersReducedMotion(context));

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: BlocListener<LanguageCubit, LanguageState>(
        listenWhen: (previous, current) =>
            current.status == LanguageStatus.ready &&
            (current.errorMessage != previous.errorMessage ||
                previous.status != LanguageStatus.ready),
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null) {
            _lastAnnouncedLanguageWarning = null;
          } else {
            _announceLanguageWarning(message);
          }
        },
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
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppScrollController scrollController,
    LanguageCubit languageController,
    NarrativeDocument narrative,
  ) => FocusTraversalGroup(
    // The skip link leads; every other control keeps reading order.
    policy: OrderedTraversalPolicy(),
    child: Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: NarrativeBackground()),
        ),
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
              // Lay out every chapter to measure navigation targets.
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
                        const PortfolioFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const NarrativeStage(),
        const BackToTopButton(),
        // Above the app bar, so the focused bypass link is never covered.
        _buildSkipLink(languageController),
      ],
    ),
  );

  Widget _buildSkipLink(LanguageCubit languageController) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Center(
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(0),
        child: SkipToContentLink(
          label: languageController.getText(
            'accessibility.skip_to_content',
            defaultValue: 'Skip to content',
          ),
          focusNode: _skipLinkFocusNode,
          onActivate: () => unawaited(_skipToContent()),
        ),
      ),
    ),
  );

  List<Widget> _buildChapters(
    BuildContext context,
    AppScrollController scrollController,
    NarrativeDocument narrative,
  ) {
    final chapters = <Widget>[];
    final mainContentId = _mainContentId(narrative);
    for (var index = 0; index < narrative.chapters.length; index += 1) {
      final chapter = narrative.chapters[index];
      final isLast = index == narrative.chapters.length - 1;
      chapters.add(
        _buildSection(
          context,
          chapter,
          isLast: isLast,
          isMainContent: chapter.id == mainContentId,
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
    BuildContext context,
    NarrativeChapter chapter, {
    required bool isLast,
    required bool isMainContent,
  }) {
    final edgeToEdge = chapter.id.isHome || chapter.id == SectionId.projects;
    final section = Container(
      key: context.read<AppScrollController>().keyFor(chapter.id),
      padding: edgeToEdge
          ? EdgeInsets.zero
          : _sectionPadding(context, isLast: isLast),
      child: _widgetFor(chapter.id),
    );
    if (!isMainContent) return section;
    return Semantics(
      identifier: 'main-content',
      container: true,
      child: Focus(
        key: const ValueKey('main-content-focus-target'),
        focusNode: _mainContentFocusNode,
        child: section,
      ),
    );
  }

  Widget _widgetFor(SectionId sectionId) => switch (sectionId.value) {
    'home' => const HomeSection(),
    'about' => const AboutSection(),
    'experience' => const ExperienceSection(),
    'proof' => const ProofSection(),
    'projects' => const ProjectsSection(),
    'packages' => const PackagesSection(),
    'writing' => const WritingSection(),
    final value => throw StateError(
      'No section widget is registered for narrative chapter "$value".',
    ),
  };
}
