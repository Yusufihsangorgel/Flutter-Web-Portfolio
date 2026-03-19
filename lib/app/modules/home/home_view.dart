import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/skills_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/contact_section.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cosmic_background.dart';
import 'package:flutter_web_portfolio/app/widgets/footer.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final AppScrollController scrollController = Get.find();
  final LanguageController languageController = Get.find();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    SharedBackgroundController.setAnimationController(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CosmicBackground(animationController: _animController),
          ),
          CustomScrollView(
            controller: scrollController.scrollController,
            slivers: [
              CustomSliverAppBar(
                scrollController: scrollController,
                languageController: languageController,
              ),
              // Home section — no scroll fade (already has FadeInDown)
              _sliverSection(scrollController.homeKey, const HomeSection()),
              // Remaining sections with scroll-triggered fade-in
              _animatedSection(scrollController.aboutKey, const AboutSection()),
              _animatedSection(scrollController.skillsKey, const SkillsSection(), delay: const Duration(milliseconds: 100)),
              _animatedSection(scrollController.experienceKey, const ExperienceSection(), delay: const Duration(milliseconds: 100)),
              _animatedSection(scrollController.projectsKey, const ProjectsSection(), delay: const Duration(milliseconds: 100)),
              _animatedSection(scrollController.contactKey, const ContactSection(), delay: const Duration(milliseconds: 100)),
              const SliverToBoxAdapter(child: PortfolioFooter()),
            ],
          ),
        ],
      ),
    );

  EdgeInsets _sectionPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width > 1400 ? 120.0 : (width > 900 ? 60.0 : 24.0);
    return EdgeInsets.symmetric(vertical: 60, horizontal: horizontal);
  }

  SliverToBoxAdapter _sliverSection(GlobalKey key, Widget child) =>
      SliverToBoxAdapter(
        child: Container(
          key: key,
          padding: _sectionPadding(context),
          child: child,
        ),
      );

  SliverToBoxAdapter _animatedSection(GlobalKey key, Widget child, {Duration delay = Duration.zero}) =>
      SliverToBoxAdapter(
        child: Container(
          key: key,
          padding: _sectionPadding(context),
          child: ScrollFadeIn(
            delay: delay,
            child: child,
          ),
        ),
      );
}
