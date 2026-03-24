import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/utils/accessibility_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/accessibility_controls.dart';

// ---------------------------------------------------------------------------
// Custom focus-ring styling, skip-link bar, section landmarks, and a
// live-region announcer for dynamic content updates.
// ---------------------------------------------------------------------------

// ── Focus ring decoration ────────────────────────────────────────────────

/// Wraps [child] in a focusable container that paints a custom accent-colored
/// focus ring when the element receives keyboard focus.
///
/// The ring uses [AppColors.accent] by default and briefly scales up on focus
/// for a polished micro-animation (respecting reduced-motion preferences).
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.child,
    this.focusNode,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.ringWidth = 2.5,
    this.ringOffset = 3.0,
    this.onFocusChange,
  });

  final Widget child;
  final FocusNode? focusNode;

  /// Colour of the focus ring.  Defaults to [AppColors.accent].
  final Color? color;
  final BorderRadius borderRadius;
  final double ringWidth;

  /// Gap between the child's edge and the ring.
  final double ringOffset;

  final ValueChanged<bool>? onFocusChange;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _ownNode = false;
  bool _focused = false;

  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownNode = true;
    }

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    if (_ownNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);

    final reduceMotion = AccessibilityUtils.shouldReduceMotion(context);
    if (!reduceMotion) {
      if (focused) {
        _scaleCtrl.forward();
      } else {
        _scaleCtrl.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a11y = AccessibilityPrefs.of(context);
    final shouldShow = _focused && a11y.showFocusIndicators;
    final ringColor = widget.color ?? AppColors.accent;

    Widget content = AnimatedContainer(
      duration: a11y.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 150),
      decoration: shouldShow
          ? BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.5),
                  blurRadius: 0,
                  spreadRadius: widget.ringOffset,
                ),
                BoxShadow(
                  color: ringColor,
                  blurRadius: 0,
                  spreadRadius: widget.ringOffset + widget.ringWidth,
                ),
                // Inner clear shadow to create the gap illusion.
                BoxShadow(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  blurRadius: 0,
                  spreadRadius: widget.ringOffset,
                ),
              ],
            )
          : null,
      child: widget.child,
    );

    // Scale animation on focus (disabled when reduced-motion is active).
    if (!a11y.reduceMotion) {
      content = ScaleTransition(scale: _scaleAnim, child: content);
    }

    return Focus(
      focusNode: _focusNode,
      onFocusChange: _handleFocusChange,
      child: content,
    );
  }
}

// ── Skip links bar ───────────────────────────────────────────────────────

/// A row of skip links rendered at the very top of the page.  Each link is
/// visually hidden until it receives keyboard focus, following the standard
/// "skip navigation" pattern.
///
/// Place this widget as the first child inside your [Scaffold] body (or at
/// the top of your main [Stack]).
class SkipLinksBar extends StatelessWidget {
  const SkipLinksBar({
    super.key,
    required this.links,
  });

  /// List of skip-link descriptors.
  final List<SkipLinkItem> links;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Skip links',
      explicitChildNodes: true,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < links.length; i++)
              FocusTraversalOrder(
                order: NumericFocusOrder(i.toDouble()),
                child: _SkipLink(item: links[i]),
              ),
          ],
        ),
      ),
    );
  }
}

/// Descriptor for a single skip link.
class SkipLinkItem {
  const SkipLinkItem({
    required this.label,
    required this.onActivate,
  });

  /// Visible / announced label, e.g. "Skip to content".
  final String label;

  /// Called when the link is activated (Enter / Space / tap).
  final VoidCallback onActivate;
}

class _SkipLink extends StatefulWidget {
  const _SkipLink({required this.item});
  final SkipLinkItem item;

  @override
  State<_SkipLink> createState() => _SkipLinkState();
}

class _SkipLinkState extends State<_SkipLink> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.item.label,
      button: true,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.item.onActivate();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.item.onActivate,
          child: AnimatedOpacity(
            opacity: _focused ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(
                  0, _focused ? 0 : -48, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section landmarks ────────────────────────────────────────────────────

/// Wraps a section of the page in a [Semantics] node with a descriptive
/// label so assistive technology can build a page-level landmark list.
///
/// ```dart
/// SectionLandmark(
///   label: 'About me',
///   child: AboutSection(),
/// )
/// ```
class SectionLandmark extends StatelessWidget {
  const SectionLandmark({
    super.key,
    required this.label,
    required this.child,
    this.isHeader = false,
  });

  /// Accessible label for the landmark (e.g. "Projects", "Contact").
  final String label;

  /// Whether this landmark should be announced as a heading.
  final bool isHeader;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      header: isHeader,
      explicitChildNodes: true,
      child: child,
    );
  }
}

// ── Live-region announcer ────────────────────────────────────────────────

/// A stateful widget that watches [message] and announces changes to
/// assistive technology via a Semantics live region.
///
/// Unlike the static [AccessibilityUtils.announcePolite], this widget
/// automatically triggers announcements when the message text changes,
/// making it ideal for content that updates over time (e.g. counters,
/// status labels, toast messages).
class LiveAnnouncer extends StatefulWidget {
  const LiveAnnouncer({
    super.key,
    required this.message,
    this.assertive = false,
    this.child,
  });

  /// The text to announce. A new announcement fires every time this value
  /// changes.
  final String message;

  /// When true, uses assertive priority (interrupts current speech).
  final bool assertive;

  /// Optional visible child — defaults to [SizedBox.shrink].
  final Widget? child;

  @override
  State<LiveAnnouncer> createState() => _LiveAnnouncerState();
}

class _LiveAnnouncerState extends State<LiveAnnouncer> {
  @override
  void didUpdateWidget(covariant LiveAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message && widget.message.isNotEmpty) {
      if (widget.assertive) {
        AccessibilityUtils.announceAssertive(widget.message);
      } else {
        AccessibilityUtils.announcePolite(widget.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

// ── Accessible interactive wrapper ───────────────────────────────────────

/// Convenience wrapper that combines [FocusRing], keyboard activation
/// (Enter / Space), mouse cursor, and semantic labelling into a single
/// widget for any clickable element.
class AccessibleTappable extends StatelessWidget {
  const AccessibleTappable({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.focusNode,
    this.isButton = true,
    this.isLink = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final FocusNode? focusNode;
  final bool isButton;
  final bool isLink;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: isButton,
      link: isLink,
      child: FocusRing(
        focusNode: focusNode,
        borderRadius: borderRadius,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                onTap();
                return null;
              },
            ),
          },
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: GestureDetector(
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}
