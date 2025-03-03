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

    // Arka plan denetleyicisinin animasyon controller'ını başlat
    SharedBackgroundController.init(this);

    // Animasyon controller'ı paylaş
    SharedBackgroundController.setAnimationController(_animController);

    // Scroll controller'ı SharedBackgroundController'a ayarla
    SharedBackgroundController.setScrollController(
      scrollController.scrollController,
    );

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
    // Fare pozisyonunu güncelle - scroll pozisyonu değiştiğinde
    SharedBackgroundController.updateMousePosition(Offset(0, _scrollPosition));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ekran genişliğine göre section yüksekliklerini ayarla
          final screenHeight = constraints.maxHeight;
          final bool isMobile = ResponsiveUtils.isMobile(context);
          final bool isTablet = ResponsiveUtils.isTablet(context);

          // Farklı section'lar için farklı yükseklik çarpanları (ekran yüksekliğinin yüzdesi)
          final homeHeightFactor = isMobile ? 1.0 : (isTablet ? 1.0 : 1.0);
          final aboutHeightFactor = isMobile ? 1.2 : (isTablet ? 1.1 : 1.0);
          final skillsHeightFactor = isMobile ? 1.5 : (isTablet ? 1.3 : 1.0);
          final experienceHeightFactor =
              isMobile ? 1.5 : (isTablet ? 1.3 : 1.0);
          final projectsHeightFactor = isMobile ? 1.5 : (isTablet ? 1.3 : 1.0);
          final contactHeightFactor = isMobile ? 1.2 : (isTablet ? 1.1 : 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Tek bir kozmik arkaplan - tüm sayfayı kapsıyor
              const Positioned.fill(child: CosmicBackground()),

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
                      noBackground:
                          true, // Arkaplan için kozmik arkaplanı kullan
                      minHeight: screenHeight * homeHeightFactor,
                      child: const HomeSection(),
                    ),
                  ),

                  // Hakkımda bölümü
                  SliverToBoxAdapter(
                    child: SectionWrapper(
                      sectionKey: scrollController.aboutKey,
                      sectionId: 'about',
                      noBackground:
                          true, // Arkaplan için kozmik arkaplanı kullan
                      minHeight: screenHeight * aboutHeightFactor,
                      child: const AboutSection(),
                    ),
                  ),

                  // Yetenekler bölümü
                  SliverToBoxAdapter(
                    child: SectionWrapper(
                      sectionKey: scrollController.skillsKey,
                      sectionId: 'skills',
                      minHeight: screenHeight * skillsHeightFactor,
                      child: const SkillsSection(),
                    ),
                  ),

                  // Deneyim bölümü
                  SliverToBoxAdapter(
                    child: SectionWrapper(
                      sectionKey: scrollController.experienceKey,
                      sectionId: 'experience',
                      minHeight: screenHeight * experienceHeightFactor,
                      child: const ExperienceSection(),
                    ),
                  ),

                  // Projeler bölümü
                  SliverToBoxAdapter(
                    child: SectionWrapper(
                      sectionKey: scrollController.projectsKey,
                      sectionId: 'projects',
                      minHeight: screenHeight * projectsHeightFactor,
                      child: const ProjectsSection(),
                    ),
                  ),

                  // İletişim bölümü
                  SliverToBoxAdapter(
                    child: SectionWrapper(
                      sectionKey: scrollController.contactKey,
                      sectionId: 'contact',
                      minHeight: screenHeight * contactHeightFactor,
                      child: const ContactSection(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
