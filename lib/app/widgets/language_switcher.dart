import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

/// Flag-emoji popup menu for switching the active language.
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
              final menuLabel = languageController.getText(
                'accessibility.language_menu',
                defaultValue: 'Language menu',
              );
              final currentLanguage = LanguageCubit.getLanguageName(
                languageState.languageCode,
              );

              return PopupMenuButton<String>(
                tooltip: '$menuLabel: $currentLanguage',
                offset: const Offset(0, 40),
                icon: ExcludeSemantics(
                  child: Row(
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
                ),
                color: AppColors.backgroundLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color:
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withValues(alpha: 0.05),
                  ),
                ),
                onSelected: languageController.changeLanguage,
                itemBuilder: (BuildContext context) => languageController
                    .supportedLanguages
                    .keys
                    .map((String languageCode) {
                      final languageName = LanguageCubit.getLanguageName(
                        languageCode,
                      );
                      final flag = LanguageCubit.getLanguageFlag(languageCode);
                      final isSelected =
                          languageState.languageCode == languageCode;

                      return PopupMenuItem<String>(
                        value: languageCode,
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              ExcludeSemantics(
                                child: Text(
                                  flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                languageName,
                                style: AppFonts.spaceGrotesk(
                                  color: isSelected
                                      ? AppColors.textBright
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                    .toList(),
              );
            },
          ),
    );
  }
}
