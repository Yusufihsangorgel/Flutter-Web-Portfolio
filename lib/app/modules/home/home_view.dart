import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/contact/contact_section.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/footer.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/background/cinematic_background.dart';
import 'package:flutter_web_portfolio/app/widgets/constellation_particles.dart';

/// Aurora Cinema home view — cinematic scene-driven portfolio.
/// Layer stack: dark base → mesh gradient → constellation particles → content.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = Get.find<AppScrollController>();
    final languageController = Get.find<LanguageController>();

    // Ensure SceneDirector recalculates after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<SceneDirector>()) {
        Get.find<SceneDirector>().recalculate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Layer 1: Cinematic gradient mesh (fills viewport)
          const Positioned.fill(
            child: CinematicBackground(),
          ),
          // Layer 2: Constellation particles (mouse-reactive)
          const Positioned.fill(
            child: ConstellationParticles(particleCount: 100),
          ),
          // Layer 3: Scrollable content — Obx triggers rebuild on language change
          Obx(() {
            // Touch reactive language value so Obx rebuilds on language switch
            languageController.currentLanguage;

            return ValueListenableBuilder<bool>(
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
          );
          }),
        ],
      ),
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
