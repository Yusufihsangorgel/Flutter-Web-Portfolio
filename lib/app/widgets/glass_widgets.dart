import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

// =============================================================================
// GlassCard — Base glassmorphism card
// =============================================================================

/// A glassmorphism card with frosted-glass backdrop blur, semi-transparent
/// background, thin luminous border, and optional gradient overlay.
///
/// Wraps content in a [RepaintBoundary] to isolate the expensive
/// [BackdropFilter] from surrounding paint operations.
///
/// Adapts automatically to light/dark theme brightness.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blurAmount = 14.0,
    this.opacity = 0.07,
    this.borderRadius = 16.0,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.showGradientOverlay = true,
    this.enableHover = true,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;

  /// Gaussian blur sigma applied to the backdrop. Range: 10-20 recommended.
  final double blurAmount;

  /// Opacity of the semi-transparent fill (0.0 - 1.0).
  /// Dark theme uses white at this opacity; light theme uses black.
  final double opacity;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Override for the 1px luminous border color. When null, defaults to
  /// white at 12% opacity.
  final Color? borderColor;

  /// Border stroke width.
  final double borderWidth;

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;

  /// Whether to paint a subtle diagonal gradient overlay.
  final bool showGradientOverlay;

  /// Whether hover should intensify blur and brighten the border.
  final bool enableHover;

  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppDurations.buttonHover,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: CinematicCurves.hoverLift,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent _) {
    if (widget.enableHover) _hoverController.forward();
  }

  void _onExit(PointerExitEvent _) {
    if (widget.enableHover) _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorderColor = Colors.white.withValues(alpha: 0.12);

    Widget card = AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        final hoverT = _hoverAnimation.value;
        final blur = widget.blurAmount + (hoverT * 6);
        final borderAlpha = isDark
            ? 0.12 + (hoverT * 0.08)
            : 0.15 + (hoverT * 0.10);

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: widget.opacity)
                      : Colors.black.withValues(
                          alpha: widget.opacity,
                        ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.borderColor ??
                        defaultBorderColor.withValues(alpha: borderAlpha),
                    width: widget.borderWidth,
                  ),
                  gradient: widget.showGradientOverlay
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.06 + hoverT * 0.03),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: widget.child,
    );

    card = Padding(padding: widget.margin, child: card);

    if (widget.onTap != null) {
      card = Semantics(
        button: true,
        label: widget.semanticLabel,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: _onEnter,
          onExit: _onExit,
          child: GestureDetector(
            onTap: widget.onTap,
            child: card,
          ),
        ),
      );
    } else {
      card = Semantics(
        label: widget.semanticLabel,
        child: MouseRegion(
          onEnter: _onEnter,
          onExit: _onExit,
          child: card,
        ),
      );
    }

    return card;
  }
}

// =============================================================================
// GlassPanel — Larger content panel with optional title bar & drag handle
// =============================================================================

/// An extended glassmorphism panel intended for larger content areas, modals,
/// or side panels.
///
/// Supports an optional title bar (with slightly elevated opacity), a drag
/// handle at the top, and a close button. Animates in with a scale + fade
/// entrance.
class GlassPanel extends StatefulWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.title,
    this.titleStyle,
    this.showDragHandle = false,
    this.showCloseButton = false,
    this.onClose,
    this.blurAmount = 16.0,
    this.opacity = 0.08,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(24),
    this.width,
    this.height,
    this.animateEntrance = true,
    this.entranceDuration,
  });

  final Widget child;
  final String? title;
  final TextStyle? titleStyle;
  final bool showDragHandle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double blurAmount;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool animateEntrance;
  final Duration? entranceDuration;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: widget.entranceDuration ?? AppDurations.normal,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: CinematicCurves.dramaticEntrance,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    if (widget.animateEntrance) {
      _entranceController.forward();
    } else {
      _entranceController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textBright : AppColors.lightTextBright;

    final Widget panelContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        if (widget.showDragHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

        // Title bar
        if (widget.title != null || widget.showCloseButton)
          _GlassPanelTitleBar(
            title: widget.title,
            titleStyle: widget.titleStyle,
            showCloseButton: widget.showCloseButton,
            onClose: widget.onClose,
            isDark: isDark,
            textColor: textColor,
          ),

        // Main content
        Flexible(
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ],
    );

    final Widget panel = GlassCard(
      blurAmount: widget.blurAmount,
      opacity: widget.opacity,
      borderRadius: widget.borderRadius,
      width: widget.width,
      height: widget.height,
      showGradientOverlay: true,
      enableHover: false,
      padding: EdgeInsets.zero,
      child: panelContent,
    );

    if (!widget.animateEntrance) return panel;

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        ),
      ),
      child: panel,
    );
  }
}

class _GlassPanelTitleBar extends StatelessWidget {
  const _GlassPanelTitleBar({
    required this.title,
    required this.titleStyle,
    required this.showCloseButton,
    required this.onClose,
    required this.isDark,
    required this.textColor,
  });

  final String? title;
  final TextStyle? titleStyle;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final bool isDark;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        // Slightly higher opacity for the title area
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: Row(
        children: [
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: titleStyle ??
                    TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
          if (title == null) const Spacer(),
          if (showCloseButton)
            Semantics(
              button: true,
              label: 'Close panel',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
}

// =============================================================================
// GlassChip — Small glass pill for tags, categories, status indicators
// =============================================================================

/// A compact glassmorphism chip with icon + text layout.
///
/// Supports an active state (filled with accent at 20%) and a hover effect
/// that brightens the border and applies a slight upward lift.
class GlassChip extends StatefulWidget {
  const GlassChip({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.isActive = false,
    this.activeColor,
    this.onTap,
    this.blurAmount = 10.0,
    this.textStyle,
    this.semanticLabel,
  }) : assert(
          label != null || child != null,
          'Provide either label or child',
        );

  /// Simple text content. Ignored when [child] is set.
  final String? label;

  /// Arbitrary widget content for full composability. Takes precedence over
  /// [label] when both are provided.
  final Widget? child;

  final IconData? icon;
  final bool isActive;

  /// Accent color used when [isActive] is true. Falls back to
  /// the theme's primary color.
  final Color? activeColor;

  final VoidCallback? onTap;
  final double blurAmount;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  State<GlassChip> createState() => _GlassChipState();
}

class _GlassChipState extends State<GlassChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppDurations.buttonHover,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: CinematicCurves.hoverLift,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.activeColor ??
        Theme.of(context).colorScheme.primary;
    final textColor = isDark ? AppColors.textBright : AppColors.lightTextBright;

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) => _hoverController.reverse(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              final hoverT = _hoverAnimation.value;
              final borderAlpha = widget.isActive
                  ? 0.30
                  : 0.12 + (hoverT * 0.12);
              final liftY = -(hoverT * 2.0);

              return Transform.translate(
                offset: Offset(0, liftY),
                child: RepaintBoundary(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: widget.blurAmount,
                        sigmaY: widget.blurAmount,
                      ),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        curve: CinematicCurves.hoverLift,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? accent.withValues(alpha: 0.20)
                              : isDark
                                  ? Colors.white.withValues(
                                      alpha: 0.06 + hoverT * 0.03,
                                    )
                                  : Colors.black.withValues(
                                      alpha: 0.05 + hoverT * 0.02,
                                    ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.isActive
                                ? accent.withValues(alpha: 0.40)
                                : Colors.white.withValues(alpha: borderAlpha),
                            width: 1,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: widget.child ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 14,
                        color: widget.isActive ? accent : textColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.label!,
                      style: widget.textStyle ??
                          TextStyle(
                            fontSize: 13,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.isActive ? accent : textColor,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GlassNavbar — Navigation bar with scroll-reactive glass intensity
// =============================================================================

/// A fixed-position glassmorphism navigation bar that transitions from fully
/// transparent at scroll offset 0 to a frosted-glass effect after scrolling
/// past [activationOffset] (default 50px).
///
/// Shadow opacity also increases gradually with scroll.
///
/// **Usage:** Place this inside a [Stack] with the main scrollable content.
/// Pass the scroll controller so the navbar can listen to scroll events.
class GlassNavbar extends StatefulWidget {
  const GlassNavbar({
    super.key,
    required this.child,
    required this.scrollController,
    this.height = 64.0,
    this.activationOffset = 50.0,
    this.maxBlur = 20.0,
    this.backgroundColor,
    this.borderRadius = 0.0,
    this.horizontalMargin = 0.0,
    this.topMargin = 0.0,
  });

  final Widget child;
  final ScrollController scrollController;
  final double height;

  /// Scroll offset (in pixels) after which the glass effect activates.
  final double activationOffset;

  /// Maximum backdrop blur sigma when fully activated.
  final double maxBlur;

  /// Override the background fill color. When null, uses theme-appropriate
  /// default.
  final Color? backgroundColor;

  /// Border radius for rounded-corner floating variants.
  final double borderRadius;

  /// Horizontal inset from screen edges (creates a floating bar look).
  final double horizontalMargin;

  /// Top inset from screen edge.
  final double topMargin;

  @override
  State<GlassNavbar> createState() => _GlassNavbarState();
}

class _GlassNavbarState extends State<GlassNavbar> {
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    // Capture current offset if the controller already has clients.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) _onScroll();
    });
  }

  @override
  void didUpdateWidget(GlassNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;
    final progress =
        (offset / widget.activationOffset).clamp(0.0, 1.0);
    if ((progress - _scrollProgress).abs() > 0.01) {
      setState(() => _scrollProgress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blur = widget.maxBlur * _scrollProgress;
    final bgAlpha = _scrollProgress * (isDark ? 0.55 : 0.65);
    final borderAlpha = _scrollProgress * (isDark ? 0.10 : 0.15);
    final shadowAlpha = _scrollProgress * 0.12;

    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.background : AppColors.lightBackground);

    return Positioned(
      top: widget.topMargin,
      left: widget.horizontalMargin,
      right: widget.horizontalMargin,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
            ),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: CinematicCurves.easeInOutCinematic,
              height: widget.height,
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: bgAlpha),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withValues(alpha: borderAlpha),
                  width: borderAlpha > 0.01 ? 1 : 0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowAlpha),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// GlassModal — Centered modal dialog with glass backdrop
// =============================================================================

/// A glassmorphism modal dialog with backdrop blur on the overlay background,
/// a glass card in the center, and configurable title / content / actions.
///
/// Entrance: scale up from 0.8 + fade in.
/// Exit: scale down + fade out.
/// Supports backdrop click to close and keyboard focus trapping.
///
/// Use [showGlassModal] helper for convenient display.
class GlassModal extends StatelessWidget {
  const GlassModal({
    super.key,
    this.title,
    this.titleStyle,
    this.content,
    this.actions,
    this.child,
    this.width,
    this.maxWidth = 480,
    this.blurAmount = 16.0,
    this.backdropBlur = 8.0,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(24),
  });

  final String? title;
  final TextStyle? titleStyle;
  final Widget? content;
  final List<Widget>? actions;

  /// When provided, replaces the title/content/actions layout entirely.
  final Widget? child;

  final double? width;
  final double maxWidth;
  final double blurAmount;
  final double backdropBlur;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textBright : AppColors.lightTextBright;
    final secondaryColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

    final modalChild = child ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: titleStyle ??
                    TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            if (content != null)
              DefaultTextStyle(
                style: TextStyle(fontSize: 14, color: secondaryColor),
                child: content!,
              ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    actions![i],
                  ],
                ],
              ),
            ],
          ],
        );

    return GlassCard(
      blurAmount: blurAmount,
      opacity: isDark ? 0.10 : 0.08,
      borderRadius: borderRadius,
      padding: padding,
      width: width,
      enableHover: false,
      showGradientOverlay: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: modalChild,
      ),
    );
  }
}

/// Shows a [GlassModal] as an overlay dialog with backdrop blur, entrance/exit
/// animations, backdrop-tap dismissal, and focus trapping.
///
/// Returns the value passed to [Navigator.pop] when the modal is closed.
Future<T?> showGlassModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double backdropBlur = 8.0,
  Duration transitionDuration = const Duration(milliseconds: 350),
  Color? barrierColor,
}) =>
  showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: transitionDuration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: CinematicCurves.dramaticEntrance,
        reverseCurve: CinematicCurves.easeInOutCinematic,
      );
      final scale = Tween<double>(begin: 0.8, end: 1.0)
          .animate(curvedAnimation);
      final fade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        reverseCurve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      );
      final blurValue = animation.value * backdropBlur;

      return Stack(
        children: [
          // Backdrop with blur
          Positioned.fill(
            child: RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurValue,
                    sigmaY: blurValue,
                  ),
                  child: ColoredBox(
                    color: (barrierColor ??
                            Colors.black.withValues(alpha: 0.4))
                        .withValues(alpha: animation.value * 0.4),
                  ),
                ),
              ),
            ),
          ),
          // Modal content
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: child,
              ),
            ),
          ),
        ],
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) =>
      FocusScope(
        autofocus: true,
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                if (barrierDismissible) Navigator.of(context).pop();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Material(
              color: Colors.transparent,
              child: builder(context),
            ),
          ),
        ),
      ),
  );

// =============================================================================
// GlassTooltip — Floating glassmorphism tooltip with auto-positioning
// =============================================================================

/// A glassmorphism tooltip that appears near the hover target with a subtle
/// arrow, smooth fade + scale entrance, and auto-positioning to stay
/// on-screen.
///
/// Dismisses on mouse leave with a short delay to prevent flicker when the
/// cursor briefly crosses the gap between the target and the tooltip.
class GlassTooltip extends StatefulWidget {
  const GlassTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferredDirection = AxisDirection.down,
    this.blurAmount = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.textStyle,
    this.showDelay = const Duration(milliseconds: 500),
    this.hideDelay = const Duration(milliseconds: 150),
    this.arrowSize = 6.0,
    this.tooltipWidget,
  });

  /// Plain-text message displayed inside the tooltip.
  final String message;

  /// The widget that the tooltip is attached to.
  final Widget child;

  /// Preferred direction to show the tooltip relative to the target.
  /// Will flip if not enough space on that side.
  final AxisDirection preferredDirection;

  final double blurAmount;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  /// Delay before showing the tooltip after hover enters.
  final Duration showDelay;

  /// Delay before hiding the tooltip after hover exits.
  final Duration hideDelay;

  /// Size of the directional arrow.
  final double arrowSize;

  /// Optional custom widget to display instead of the text [message].
  final Widget? tooltipWidget;

  @override
  State<GlassTooltip> createState() => _GlassTooltipState();
}

class _GlassTooltipState extends State<GlassTooltip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _animController;
  bool _mouseInTarget = false;
  bool _mouseInTooltip = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _GlassTooltipOverlay(
        link: _layerLink,
        message: widget.message,
        tooltipWidget: widget.tooltipWidget,
        preferredDirection: widget.preferredDirection,
        blurAmount: widget.blurAmount,
        padding: widget.padding,
        textStyle: widget.textStyle,
        arrowSize: widget.arrowSize,
        animation: _animController,
        onMouseEnter: () {
          _mouseInTooltip = true;
        },
        onMouseExit: () {
          _mouseInTooltip = false;
          _scheduleHide();
        },
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _scheduleShow() {
    Future.delayed(widget.showDelay, () {
      if (mounted && _mouseInTarget) {
        _showTooltip();
      }
    });
  }

  void _scheduleHide() {
    Future.delayed(widget.hideDelay, () {
      if (mounted && !_mouseInTarget && !_mouseInTooltip) {
        _animController.reverse().then((_) {
          _removeOverlay();
        });
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _mouseInTarget = true;
          _scheduleShow();
        },
        onExit: (_) {
          _mouseInTarget = false;
          _scheduleHide();
        },
        child: widget.child,
      ),
    );
  }
}

class _GlassTooltipOverlay extends StatelessWidget {
  const _GlassTooltipOverlay({
    required this.link,
    required this.message,
    required this.tooltipWidget,
    required this.preferredDirection,
    required this.blurAmount,
    required this.padding,
    required this.textStyle,
    required this.arrowSize,
    required this.animation,
    required this.onMouseEnter,
    required this.onMouseExit,
  });

  final LayerLink link;
  final String message;
  final Widget? tooltipWidget;
  final AxisDirection preferredDirection;
  final double blurAmount;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double arrowSize;
  final Animation<double> animation;
  final VoidCallback onMouseEnter;
  final VoidCallback onMouseExit;

  Offset _getOffset(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.down:
        return Offset(0, arrowSize + 4);
      case AxisDirection.up:
        return Offset(0, -(arrowSize + 4));
      case AxisDirection.right:
        return Offset(arrowSize + 4, 0);
      case AxisDirection.left:
        return Offset(-(arrowSize + 4), 0);
    }
  }

  Alignment _getTargetAnchor(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.down:
        return Alignment.bottomCenter;
      case AxisDirection.up:
        return Alignment.topCenter;
      case AxisDirection.right:
        return Alignment.centerRight;
      case AxisDirection.left:
        return Alignment.centerLeft;
    }
  }

  Alignment _getFollowerAnchor(AxisDirection direction) {
    switch (direction) {
      case AxisDirection.down:
        return Alignment.topCenter;
      case AxisDirection.up:
        return Alignment.bottomCenter;
      case AxisDirection.right:
        return Alignment.centerLeft;
      case AxisDirection.left:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textBright : AppColors.lightTextBright;
    final direction = preferredDirection;

    return CompositedTransformFollower(
      link: link,
      showWhenUnlinked: false,
      offset: _getOffset(direction),
      targetAnchor: _getTargetAnchor(direction),
      followerAnchor: _getFollowerAnchor(direction),
      child: MouseRegion(
        onEnter: (_) => onMouseEnter(),
        onExit: (_) => onMouseExit(),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final fadeValue = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ).value;
            final scaleValue = Tween<double>(begin: 0.92, end: 1.0)
                .transform(fadeValue);

            return Opacity(
              opacity: fadeValue,
              child: Transform.scale(
                scale: scaleValue,
                child: child,
              ),
            );
          },
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurAmount,
                  sigmaY: blurAmount,
                ),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: tooltipWidget ??
                      Text(
                        message,
                        style: textStyle ??
                            TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
