import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;

/// Full-screen navigation for compact viewports.
///
/// Usage:
/// ```dart
/// NavigationOverlay.show(context);
/// ```
class NavigationOverlay extends StatefulWidget {
  const NavigationOverlay({super.key});

  static void show(BuildContext context) {
    final reduceMotion = prefersReducedMotion(context);
    url_strategy.setTransientOverlayOpen(true);
    unawaited(
      Navigator.of(context)
          .push(
            PageRouteBuilder<void>(
              opaque: false,
              barrierDismissible: true,
              barrierColor: Colors.transparent,
              transitionDuration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              reverseTransitionDuration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              pageBuilder: (_, _, _) => const NavigationOverlay(),
            ),
          )
          .whenComplete(() => url_strategy.setTransientOverlayOpen(false)),
    );
  }

  @override
  State<NavigationOverlay> createState() => _NavigationOverlayState();
}

class _NavigationOverlayState extends State<NavigationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _backdropBlur;
  late Animation<double> _overlayOpacity;

  int _hoveredIndex = -1;
  bool _reduceMotion = false;

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<_MenuItem> _buildMenuItems() {
    // Drop 'home' — the logo already scrolls to top, so listing it here
    // produces a confusing duplicate row at the top of the drawer.
    final sections = context
        .read<AppScrollController>()
        .sectionIds
        .where((s) => s != 'home')
        .toList();
    return [
      for (var i = 0; i < sections.length; i++)
        _MenuItem(
          sectionId: sections[i],
          number: (i + 1).toString().padLeft(2, '0'),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _backdropBlur = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _overlayOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _masterController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = prefersReducedMotion(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _masterController.value = 1;
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  void _close() {
    url_strategy.setTransientOverlayOpen(false);
    if (_reduceMotion) {
      Navigator.of(context).pop();
      return;
    }
    _masterController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _navigateToSection(String key) {
    final scrollController = context.read<AppScrollController>();
    _close();
    Future.delayed(
      _reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      () {
        scrollController.scrollToSection(key);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = context.read<LanguageCubit>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.tablet;
    final menuItems = _buildMenuItems();

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _masterController,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: _close,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _reduceMotion ? 0 : _backdropBlur.value,
                    sigmaY: _reduceMotion ? 0 : _backdropBlur.value,
                  ),
                  child: Container(
                    color: AppColors.cobalt.withValues(
                      alpha: 0.94 * _overlayOpacity.value,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 24,
              right: 24,
              child: Opacity(
                opacity: _overlayOpacity.value,
                child: IconButton(
                  onPressed: _close,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
            ),

            // Menu items
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? screenWidth * 0.9 : 700,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(menuItems.length, (index) {
                    final item = menuItems[index];
                    final itemDelay = 0.15 + (index * 0.06);
                    final itemEnd = (itemDelay + 0.25).clamp(0.0, 1.0);

                    final itemAnimation = Tween<double>(begin: 0, end: 1)
                        .animate(
                          CurvedAnimation(
                            parent: _masterController,
                            curve: Interval(
                              itemDelay,
                              itemEnd,
                              curve: MotionCurves.emphasizedDecelerate,
                            ),
                          ),
                        );

                    final label = languageController.getText(
                      'nav.${item.sectionId}',
                      defaultValue:
                          item.sectionId[0].toUpperCase() +
                          item.sectionId.substring(1),
                    );

                    return Opacity(
                      opacity: itemAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - itemAnimation.value)),
                        child: _MenuItemWidget(
                          item: item,
                          label: label,
                          isSelected:
                              context
                                  .read<AppScrollController>()
                                  .activeSection ==
                              item.sectionId,
                          isHovered: _hoveredIndex == index,
                          isMobile: isMobile,
                          onTap: () => _navigateToSection(item.sectionId),
                          onHover: (hovered) {
                            setState(
                              () => _hoveredIndex = hovered ? index : -1,
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.sectionId, required this.number});
  final String sectionId;
  final String number;
}

class _MenuItemWidget extends StatelessWidget {
  const _MenuItemWidget({
    required this.item,
    required this.label,
    required this.isSelected,
    required this.isHovered,
    required this.isMobile,
    required this.onTap,
    required this.onHover,
  });

  final _MenuItem item;
  final String label;
  final bool isSelected;
  final bool isHovered;
  final bool isMobile;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    const textColor = AppColors.white;
    const accentColor = AppColors.acid;
    final fontSize = isMobile ? 28.0 : 48.0;
    final motionDuration = prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return AccessibleAction(
      onTap: onTap,
      onHoverChanged: onHover,
      semanticLabel: label,
      selected: isSelected,
      child: AnimatedContainer(
        duration: motionDuration,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 12 : 16,
          horizontal: 0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Number
            AnimatedDefaultTextStyle(
              duration: motionDuration,
              style: AppFonts.spaceGrotesk(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: isHovered
                    ? accentColor
                    : textColor.withValues(alpha: 0.4),
              ),
              child: Text(item.number),
            ),
            SizedBox(width: isMobile ? 22 : 38),

            // Label
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: motionDuration,
                style: AppFonts.spaceGrotesk(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isHovered ? accentColor : textColor,
                  letterSpacing: -fontSize * 0.025,
                ),
                child: Text(label),
              ),
            ),

            // Arrow on hover
            AnimatedOpacity(
              duration: motionDuration,
              opacity: isHovered ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: motionDuration,
                offset: Offset(isHovered ? 0 : -0.5, 0),
                child: Icon(
                  Icons.north_east_rounded,
                  color: accentColor,
                  size: isMobile ? 20 : 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
