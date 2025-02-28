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
import 'package:flutter_web_portfolio/app/widgets/cosmic_background.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_web_portfolio/main.dart';

/// Portföyün ana sayfa görünümü
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final AppScrollController scrollController = Get.find();
  final LanguageController languageController = Get.find();
  late AnimationController _animController;
  String _currentSection = 'home';
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: false);

    // Arka plan denetleyicisini başlat
    SharedBackgroundController.init(this);

    scrollController.scrollController.addListener(_updateScrollPosition);
    scrollController.activeSection.listen((section) {
      setState(() {
        _currentSection = section;
      });
    });
  }

  void _updateScrollPosition() {
    setState(() {
      _scrollPosition = scrollController.scrollController.offset;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tek bir kozmik arkaplan - tüm sayfayı kapsıyor
          Positioned.fill(child: CosmicBackground()),

          // Sayfa içeriği
          CustomScrollView(
            controller: scrollController.scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              CustomSliverAppBar(
                scrollController: scrollController,
                languageController: languageController,
              ),

              // Ana bölüm - varsayılan başlangıç
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.homeKey,
                  sectionId: 'home',
                  noBackground: true, // Arkaplan için kozmik arkaplanı kullan
                  child: const HomeSection(),
                ),
              ),

              // Hakkımda bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.aboutKey,
                  sectionId: 'about',
                  noBackground: true, // Arkaplan için kozmik arkaplanı kullan
                  child: const AboutSection(),
                ),
              ),

              // Yetenekler bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.skillsKey,
                  sectionId: 'skills',
                  child: const SkillsSection(),
                ),
              ),

              // Deneyim bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.experienceKey,
                  sectionId: 'experience',
                  child: const ExperienceSection(),
                ),
              ),

              // Projeler bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.projectsKey,
                  sectionId: 'projects',
                  child: const ProjectsSection(),
                ),
              ),

              // İletişim bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.contactKey,
                  sectionId: 'contact',
                  child: const ContactSection(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
