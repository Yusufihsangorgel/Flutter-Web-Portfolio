import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/home_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/about_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/experience_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/skills_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/references_section.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/contact_section.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';
import 'package:flutter_web_portfolio/app/widgets/section_wrapper.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/cosmic_background.dart';
import 'package:flutter_web_portfolio/main.dart';

/// Portföyün ana sayfa görünümü
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final LanguageController languageController = Get.find();
  final ThemeController themeController = Get.find();
  final AppScrollController scrollController = Get.find();

  @override
  void initState() {
    super.initState();

    // Arka plan denetleyicisini başlat
    SharedBackgroundController.init(this);

    // Scroll denetleyicisini paylaşılan denetleyiciye ayarla
    SharedBackgroundController.setScrollController(
      scrollController.scrollController,
    );

    // Sayfa yüksekliğini ölç
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && scrollController.scrollController.hasClients) {
          final totalHeight =
              scrollController.scrollController.position.maxScrollExtent +
              MediaQuery.of(context).size.height;
          SharedBackgroundController.updatePageHeight(totalHeight);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Kozmik arka plan
          const CosmicBackground(),

          // Sayfa içeriği
          CustomScrollView(
            controller: scrollController.scrollController,
            slivers: [
              // App Bar
              CustomSliverAppBar(
                languageController: languageController,
                themeController: themeController,
                scrollController: scrollController,
                actions: [
                  // Dil değiştirme butonu
                  const LanguageSwitcher(),
                  const SizedBox(width: 16),
                  // Tema değiştirme butonu
                  IconButton(
                    icon: Icon(
                      themeController.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () => themeController.toggleTheme(),
                    tooltip:
                        themeController.isDarkMode
                            ? languageController.getText(
                              'theme.light_mode',
                              defaultValue: 'Light Mode',
                            )
                            : languageController.getText(
                              'theme.dark_mode',
                              defaultValue: 'Dark Mode',
                            ),
                  ),
                ],
              ),

              // Ana bölüm
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.homeKey,
                  sectionId: 'home',
                  child: const HomeSection(),
                ),
              ),

              // Hakkında bölümü
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.aboutKey,
                  sectionId: 'about',
                  child: const AboutSection(),
                ),
              ),

              // Diğer bölümler
              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.skillsKey,
                  sectionId: 'skills',
                  child: const SkillsSection(),
                ),
              ),

              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.experienceKey,
                  sectionId: 'experience',
                  child: const ExperienceSection(),
                ),
              ),

              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.projectsKey,
                  sectionId: 'projects',
                  child: const ProjectsSection(),
                ),
              ),

              SliverToBoxAdapter(
                child: SectionWrapper(
                  sectionKey: scrollController.referencesKey,
                  sectionId: 'references',
                  child: const ReferencesSection(),
                ),
              ),

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
