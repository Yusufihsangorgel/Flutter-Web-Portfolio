import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';

/// Flag-emoji popup menu for switching the active language.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final languageController = Get.find<LanguageController>();

      return Obx(() {
        final accent = Get.find<SceneDirector>().currentAccent.value;

        return Semantics(
          label: 'Language',
          child: PopupMenuButton<String>(
          offset: const Offset(0, 40),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageController.languageInfo['flag'] ?? '',
                style: const TextStyle(fontSize: 24),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
          color: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white : Colors.black).withValues(alpha: 0.05),
            ),
          ),
          onSelected: languageController.changeLanguage,
          itemBuilder: (BuildContext context) =>
              languageController.supportedLanguages.keys.map((
            String languageCode,
          ) {
            final languageName = LanguageController.getLanguageName(
              languageCode,
            );
            final flag = LanguageController.getLanguageFlag(languageCode);
            final isSelected =
                languageController.currentLanguage == languageCode;

            return PopupMenuItem<String>(
              value: languageCode,
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      languageName,
                      style: GoogleFonts.spaceGrotesk(
                        color: isSelected
                            ? AppColors.textBright
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ));
      });
    } catch (e) {
      // Fails gracefully if LanguageController isn't registered yet
      dev.log('LanguageSwitcher build failed', name: 'LanguageSwitcher', error: e);
      return const SizedBox.shrink();
    }
  }
}
