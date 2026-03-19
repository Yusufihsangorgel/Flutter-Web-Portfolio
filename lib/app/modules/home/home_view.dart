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
import 'package:flutter_web_portfolio/app/widgets/section_wrapper.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cosmic_background.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';

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
      duration: const Duration(seconds: 10),
    )..repeat();

    SharedBackgroundController.init(this);
    SharedBackgroundController.setAnimationController(_animController);
    SharedBackgroundController.setScrollController(
      scrollController.scrollController,
    );

    scrollController.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = scrollController.scrollController.offset;
    SharedBackgroundController.updateMousePosition(Offset(0, offset));
  }

  @override
  void dispose() {
    scrollController.scrollController.removeListener(_onScroll);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final isMobile = ResponsiveUtils.isMobile(context);
          final isTablet = ResponsiveUtils.isTablet(context);

          final heightFactor = isMobile ? 1.5 : (isTablet ? 1.3 : 1.0);
          final compactFactor = isMobile ? 1.2 : (isTablet ? 1.1 : 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: CosmicBackground()),
              CustomScrollView(
                controller: scrollController.scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CustomSliverAppBar(
                    scrollController: scrollController,
                    languageController: languageController,
                  ),
                  _section(scrollController.homeKey, 'home', screenHeight, const HomeSection()),
                  _section(scrollController.aboutKey, 'about', screenHeight * compactFactor, const AboutSection()),
                  _section(scrollController.skillsKey, 'skills', screenHeight * heightFactor, const SkillsSection()),
                  _section(scrollController.experienceKey, 'experience', screenHeight * heightFactor, const ExperienceSection()),
                  _section(scrollController.projectsKey, 'projects', screenHeight * heightFactor, const ProjectsSection()),
                  _section(scrollController.contactKey, 'contact', screenHeight * compactFactor, const ContactSection()),
                ],
              ),
            ],
          );
        },
      ),
    );

  SliverToBoxAdapter _section(GlobalKey key, String id, double minHeight, Widget child) =>
      SliverToBoxAdapter(
        child: SectionWrapper(
          sectionKey: key,
          sectionId: id,
          noBackground: true,
          minHeight: minHeight,
          child: child,
        ),
      );
}
