import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';
import 'widgets/galaxy_view.dart';

/// Main layout shell for the Skills section.
class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final LanguageController languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Create a full-screen section
    final galaxySize = math.min(screenWidth * 0.85, 800.0);
    final centralPlanetSize = galaxySize * 0.2; // Central planet size

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      // Background color removed; the overall background comes from home_view
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            child: SectionTitle(
              title: languageController.getText(
                'skills_section.title',
                defaultValue: 'Beceriler',
              ),
              alignment: CrossAxisAlignment.center,
            ),
          ),

          // Galaxy view
          SizedBox(
            width: galaxySize,
            height: galaxySize,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Obx(() {
                final skillsList =
                    languageController.cvData['skills'] as List<dynamic>? ?? [];
                return GalaxyView(
                  galaxySize: galaxySize,
                  centralPlanetSize: centralPlanetSize,
                  skillCategories: skillsList,
                );
              }),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
