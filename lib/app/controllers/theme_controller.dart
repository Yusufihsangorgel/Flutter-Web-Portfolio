import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_theme.dart' as core_theme;

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  ThemeData get darkTheme => core_theme.AppTheme.dark;

  bool get isDarkMode => true;
  Color get backgroundColor => AppColors.background;
  Color get cardColor => AppColors.surface;
  Color get surfaceColor => AppColors.surfaceVariant;
  Color get primaryTextColor => AppColors.textPrimary;
  Color get secondaryTextColor => AppColors.textSecondary;
  Color get primaryColor => AppColors.primary;
  Color get accentColor => AppColors.primary;
  Color get secondaryColor => AppColors.primary;
}
