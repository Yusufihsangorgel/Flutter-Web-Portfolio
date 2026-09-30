import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

final class SceneAccentBuilder extends StatelessWidget {
  const SceneAccentBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Color accent) builder;

  @override
  Widget build(BuildContext context) => builder(context, AppColors.accent);
}
