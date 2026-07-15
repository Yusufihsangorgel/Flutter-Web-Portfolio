import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:flutter_web_portfolio/app/widgets/neon_effects.dart';

part 'footer/footer_brand.dart';
part 'footer/footer_quick_links.dart';
part 'footer/footer_connect.dart';
part 'footer/footer_bottom_bar.dart';

// =============================================================================
// PremiumFooter
// =============================================================================

/// A compact footer with navigation and current professional focus.
class PremiumFooter extends StatelessWidget {
  const PremiumFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= Breakpoints.tablet;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundDark.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated gradient neon top border ──────────────────────────
            const NeonLine(
              thickness: 2,
              intensity: 0.8,
              blurRadius: 16,
              travelDuration: Duration(milliseconds: 4000),
            ),

            // ── Main content area ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24,
                vertical: isDesktop ? 56 : 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop
                    ? const _DesktopLayout()
                    : const _MobileLayout(),
              ),
            ),

            // ── Bottom bar with "Built with Flutter", version, etc. ──────
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Desktop three-column layout
// =============================================================================

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left — brand identity
      Expanded(flex: 3, child: _BrandColumn()),
      SizedBox(width: 48),
      // Center — quick navigation links
      Expanded(flex: 2, child: _QuickLinksColumn()),
      SizedBox(width: 48),
      // Right — current professional focus
      Expanded(flex: 3, child: _ConnectColumn()),
    ],
  );
}

// =============================================================================
// Mobile stacked layout
// =============================================================================

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      _BrandColumn(centered: true),
      SizedBox(height: 36),
      _QuickLinksColumn(centered: true),
      SizedBox(height: 36),
      _ConnectColumn(centered: true),
    ],
  );
}
