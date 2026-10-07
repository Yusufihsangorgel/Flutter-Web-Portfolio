import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_dimensions.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

/// Atlas colours that the shared theme does not define.
abstract final class AtlasColors {
  static const ink = Color(0xFF14130F);
  static const indexPaper = Color(0xFFF2EFE8);
  static const dividerPaper = Color(0xFF10110F);
  static const dividerInk = Color(0xFFF4EFE5);
  static const accent = AppColors.cobalt;
  static const rule = Color(0x4014130F);
  static const introText = Color(0xC914130F);
  static const spotlightText = Color(0xBF14130F);
  static const mutedText = Color(0x9914130F);
  static const idleIcon = Color(0x8014130F);
  static const selectedRow = Color(0x0F1E51FF);
}

/// Opacity steps applied to a project palette's foreground colour.
abstract final class AtlasAlpha {
  static const surface = 0.035;
  static const rule = 0.28;
  static const strongRule = 0.3;
  static const secondary = 0.65;
  static const caption = 0.68;
  static const meta = 0.72;
  static const label = 0.78;
  static const spotlight = 0.82;
  static const body = 0.84;
}

/// Responsive geometry shared by every atlas surface.
@immutable
final class AtlasLayout {
  const AtlasLayout.forWidth(this.width);

  factory AtlasLayout.of(BuildContext context) =>
      AtlasLayout.forWidth(MediaQuery.sizeOf(context).width);

  /// Gutter between the artifact and narrative columns.
  static const double columnGap = 68;
  static const int artifactFlex = 58;
  static const int narrativeFlex = 42;

  /// Viewport extents beyond the visible area at which images start loading,
  /// so an artifact one screen away is already decoded when scrolled in.
  static const double lazyLoadLead = 2;

  final double width;

  bool get desktop => width >= Breakpoints.desktop;
  bool get tablet => width >= Breakpoints.tablet;
  bool get narrow => width < Breakpoints.mobile;

  /// Portrait artifact crops replace landscape boards below the tablet width.
  bool get usesCompactArtifacts => !tablet;

  double get horizontalPadding => width > AppDimensions.maxContentWidth
      ? AppDimensions.sectionPaddingDesktop
      : tablet
      ? AppDimensions.sectionPaddingTablet
      : AppDimensions.sectionPaddingMobile;
}

/// Uppercase-style Space Grotesk labels used across the atlas.
abstract final class AtlasText {
  static TextStyle label({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w800,
    double? letterSpacing,
  }) => AppFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
