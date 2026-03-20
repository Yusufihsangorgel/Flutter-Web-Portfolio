import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/github_activity.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/skill_bar_chart.dart';
import 'package:flutter_web_portfolio/app/widgets/skill_orbit.dart';

/// About Section — "The Introduction"
/// Giant watermark, flashlight photo, floating tech pills.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final data = languageController.cvData['personal_info'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -20,
            left: -10,
            child: Obx(() => Text(
              languageController.getText('nav.about', defaultValue: 'About').toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: ResponsiveUtils.getValueForScreenType<double>(
                  context: context,
                  mobile: 48.0,
                  tablet: screenWidth * 0.14,
                  desktop: screenWidth * 0.18,
                ),
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.02),
                letterSpacing: -4,
              ),
            )),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              if (isMobile)
                _buildMobileLayout(data, languageController)
              else
                _buildDesktopLayout(data, languageController),
              // GitHub Activity
              const GitHubActivity(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, dynamic> data, LanguageController languageController) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: ScrollFadeIn(
          child: _BioContent(data: data, languageController: languageController),
        ),
      ),
      const SizedBox(width: 48),
      Expanded(
        flex: 2,
        child: ScrollFadeIn(
          delay: AppDurations.staggerMedium,
          child: _FlashlightPhoto(),
        ),
      ),
    ],
  );

  Widget _buildMobileLayout(Map<String, dynamic> data, LanguageController languageController) => Column(
    children: [
      ScrollFadeIn(child: _FlashlightPhoto()),
      const SizedBox(height: 32),
      ScrollFadeIn(
        delay: AppDurations.staggerMedium,
        child: _BioContent(data: data, languageController: languageController),
      ),
    ],
  );
}

// Bio content with staggered word reveal
class _BioContent extends StatefulWidget {
  const _BioContent({required this.data, required this.languageController});

  final Map<String, dynamic> data;
  final LanguageController languageController;

  @override
  State<_BioContent> createState() => _BioContentState();
}

class _BioContentState extends State<_BioContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;

  // Hardcoded relative proficiency per category.
  static const _proficiencyMap = <String, double>{
    'Mobile': 0.95,
    'Backend': 0.80,
    'Frontend': 0.70,
    'DevOps': 0.65,
  };

  @override
  void initState() {
    super.initState();
    // Total animation budget: 800ms per bar + 100ms stagger * 3 gaps = 1100ms.
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  List<String> _categoryLabels() {
    final skills =
        widget.languageController.cvData['skills'] as List? ?? [];
    return skills
        .map<String>((s) => (s as Map<String, dynamic>)['category'] as String)
        .toList();
  }

  List<double> _categoryProficiencies(List<String> labels) =>
      labels.map((l) => _proficiencyMap[l] ?? 0.60).toList();

  @override
  Widget build(BuildContext context) {
    final sceneDirector = Get.find<SceneDirector>();
    final isMobile = ResponsiveUtils.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Obx(() => NumberedSectionHeading(
          number: '01',
          title: widget.languageController.getText(
            'about_section.title',
            defaultValue: 'About Me',
          ),
          accent: sceneDirector.currentAccent.value,
        )),
        const SizedBox(height: 24),
        Text(
          (widget.data['bio'] as String?) ??
              widget.languageController.getText(
                'about_section.bio',
                defaultValue:
                    'I enjoy creating things that live on the internet, '
                    'whether that be websites, applications, or anything in between. '
                    'My goal is to always build products that provide pixel-perfect, '
                    'performant experiences.',
              ),
          style: AppTypography.body,
        ),
        const SizedBox(height: 16),
        Text(
          widget.languageController.getText(
            'about_section.bio2',
            defaultValue:
                'Here are a few technologies I\'ve been working with recently:',
          ),
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        // Floating tech pills — derived from cvData skills
        _FloatingTechPills(
          sceneDirector: sceneDirector,
          languageController: widget.languageController,
        ),
        const SizedBox(height: 32),
        // Skill orbit — desktop only (too dense for mobile).
        if (!isMobile)
          ScrollFadeIn(
            delay: AppDurations.staggerMedium,
            child: Obx(() {
              final accent = sceneDirector.currentAccent.value;
              final skills =
                  widget.languageController.cvData['skills'] as List? ?? [];
              if (skills.isEmpty) return const SizedBox.shrink();
              return SkillOrbit(skills: skills, accent: accent);
            }),
          ),
        if (!isMobile) const SizedBox(height: 32),
        // Skill proficiency chart
        ScrollFadeIn(
          delay: AppDurations.staggerMedium,
          child: Obx(() {
            final accent = sceneDirector.currentAccent.value;
            final labels = _categoryLabels();
            if (labels.isEmpty) return const SizedBox.shrink();
            return _SkillChartAnimator(
              controller: _barController,
              accent: accent,
              categories: labels,
              proficiencies: _categoryProficiencies(labels),
              barHeight: isMobile ? 20.0 : 28.0,
            );
          }),
        ),
      ],
    );
  }
}

/// Wrapper that triggers the bar animation when the [ScrollFadeIn] ancestor
/// first becomes visible. It starts the supplied [controller] on init so the
/// bars animate in sync with the scroll-triggered fade.
class _SkillChartAnimator extends StatefulWidget {
  const _SkillChartAnimator({
    required this.controller,
    required this.accent,
    required this.categories,
    required this.proficiencies,
    required this.barHeight,
  });

  final AnimationController controller;
  final Color accent;
  final List<String> categories;
  final List<double> proficiencies;
  final double barHeight;

  @override
  State<_SkillChartAnimator> createState() => _SkillChartAnimatorState();
}

class _SkillChartAnimatorState extends State<_SkillChartAnimator> {
  @override
  void initState() {
    super.initState();
    // Begin fill animation (the ScrollFadeIn handles visibility gating).
    if (!widget.controller.isAnimating && !widget.controller.isCompleted) {
      widget.controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) => SkillBarChart(
        categories: widget.categories,
        proficiencies: widget.proficiencies,
        accent: widget.accent,
        animation: widget.controller,
        barHeight: widget.barHeight,
      );
}

// Floating tech pills — data-driven from cvData skills
class _FloatingTechPills extends StatelessWidget {
  const _FloatingTechPills({
    required this.sceneDirector,
    required this.languageController,
  });
  final SceneDirector sceneDirector;
  final LanguageController languageController;

  List<String> _getTechnologies() {
    final skills = languageController.cvData['skills'] as List? ?? [];
    return skills.map<String>((s) {
      final items = ((s as Map<String, dynamic>)['items'] as List?) ?? [];
      return items.take(2).join(' & ');
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final accent = sceneDirector.currentAccent.value;
    final technologies = _getTechnologies();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: technologies.map((tech) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          tech,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            color: accent,
          ),
        ),
      )).toList(),
    );
  });
}

// TODO: extract FlashlightPhoto to its own widget file if reused elsewhere
class _FlashlightPhoto extends StatefulWidget {
  @override
  State<_FlashlightPhoto> createState() => _FlashlightPhotoState();
}

class _FlashlightPhotoState extends State<_FlashlightPhoto> {
  Offset _mousePos = const Offset(0.5, 0.5);
  bool _hovered = false;

  /// Max tilt angle in radians (3 degrees).
  static const double _maxTilt = 3.0 * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    // Normalized values centered around 0 (-1 to 1 range)
    final dx = (_mousePos.dx - 0.5) * 2.0;
    final dy = (_mousePos.dy - 0.5) * 2.0;

    // Tilt transform: rotateY follows horizontal, rotateX follows vertical
    final tiltTransform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateY(_hovered ? dx * _maxTilt : 0)
      ..rotateX(_hovered ? -dy * _maxTilt : 0);

    // Shadow shifts opposite to tilt direction
    final shadowOffsetX = _hovered ? -dx * 8.0 : 0.0;
    final shadowOffsetY = _hovered ? -dy * 8.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        setState(() {
          _mousePos = Offset(
            e.localPosition.dx / box.size.width,
            e.localPosition.dy / box.size.height,
          );
        });
      },
      onExit: (_) => setState(() {
        _hovered = false;
        _mousePos = const Offset(0.5, 0.5);
      }),
      child: AnimatedContainer(
        duration: AppDurations.medium,
        curve: CinematicCurves.hoverLift,
        transform: tiltTransform,
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.heroAccent.withValues(alpha: 0.12),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: Offset(shadowOffsetX, shadowOffsetY),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: Offset(shadowOffsetX * 0.5, shadowOffsetY * 0.5),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => RadialGradient(
              center: Alignment(
                _mousePos.dx * 2 - 1,
                _mousePos.dy * 2 - 1,
              ),
              radius: _hovered ? 1.2 : 2.0,
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.8),
                Colors.white.withValues(alpha: _hovered ? 0.2 : 0.5),
              ],
              stops: const [0.0, 0.4, 1.0],
            ).createShader(bounds),
            child: Image.asset(
              'assets/images/me.jpeg',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: AppColors.backgroundLight,
                  child: Icon(
                    Icons.person,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
