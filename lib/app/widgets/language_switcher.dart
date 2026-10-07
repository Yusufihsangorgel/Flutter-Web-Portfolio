import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

/// Compact typographic menu for switching the active language.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = BlocProvider.of<LanguageCubit>(context);

    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) =>
          BlocSelector<SceneDirector, SceneState, Color>(
            selector: (state) => state.currentAccent,
            builder: (context, accent) {
              final menuLabel = context.strings.accessibilityLanguageMenu;
              final currentLanguage = LanguageCubit.getLanguageName(
                languageState.languageCode,
              );
              return PopupMenuButton<String>(
                tooltip: '$menuLabel: $currentLanguage',
                offset: const Offset(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                icon: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        languageState.languageCode.toUpperCase(),
                        style: AppFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBright,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 15,
                      ),
                    ],
                  ),
                ),
                color: AppColors.backgroundLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                  side: BorderSide(
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withValues(alpha: 0.05),
                  ),
                ),
                onSelected: (languageCode) =>
                    _selectLanguage(context, languageController, languageCode),
                itemBuilder: (context) => languageController.supportedLanguages
                    .map(
                      (code) => _languageItem(
                        code,
                        languageState.languageCode == code,
                        accent,
                      ),
                    )
                    .toList(),
              );
            },
          ),
    );
  }
}

void _selectLanguage(
  BuildContext context,
  LanguageCubit languageController,
  String languageCode,
) {
  final urlSection = url_strategy.getUrlHash();
  final sectionToPreserve = urlSection.isNotEmpty
      ? urlSection
      : context.read<AppScrollController>().activeSection;
  unawaited(
    languageController.selectLanguage(
      languageCode,
      preserveSection: sectionToPreserve,
    ),
  );
}

PopupMenuItem<String> _languageItem(String code, bool selected, Color accent) {
  final name = LanguageCubit.getLanguageName(code);
  return PopupMenuItem<String>(
    value: code,
    height: 48,
    child: Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            code.toUpperCase(),
            style: AppFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? accent : AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Text(
            name,
            style: AppFonts.spaceGrotesk(
              color: selected ? AppColors.textBright : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 12),
          Icon(Icons.check_rounded, size: 16, color: accent),
        ],
      ],
    ),
  );
}
