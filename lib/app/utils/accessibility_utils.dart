import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// ---------------------------------------------------------------------------
// Accessibility utilities — media-query awareness, keyboard helpers,
// screen-reader announcements, and WCAG color-contrast checking.
// ---------------------------------------------------------------------------

/// Reads OS-level accessibility media queries and exposes helpers that
/// respect reduced-motion, high-contrast, and color-scheme preferences.
class AccessibilityUtils {
  const AccessibilityUtils._();

  // ── Media-query readers ────────────────────────────────────────────────

  /// `true` when the OS or browser advertises `prefers-reduced-motion: reduce`.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// `true` when the OS or browser advertises `prefers-contrast: more` (or
  /// the Flutter equivalent high-contrast flag).
  static bool prefersHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// `true` when the platform reports a dark color scheme.
  static bool prefersDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// Returns a multiplier for animation durations.
  ///
  /// * `0.0` when reduced motion is active (skip animations entirely).
  /// * `1.0` otherwise (full-length animations).
  static double animationDurationMultiplier(BuildContext context) {
    return shouldReduceMotion(context) ? 0.0 : 1.0;
  }

  /// Convenience: scales a [Duration] according to the current motion pref.
  static Duration scaledDuration(BuildContext context, Duration base) {
    final multiplier = animationDurationMultiplier(context);
    return Duration(
      milliseconds: (base.inMilliseconds * multiplier).round(),
    );
  }

  // ── Screen-reader announcements ────────────────────────────────────────

  /// Posts a polite live-region announcement so assistive technology can
  /// surface it without interrupting the user's current focus.
  static void announcePolite(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Posts an assertive live-region announcement that interrupts what the
  /// screen reader is currently reading.
  static void announceAssertive(String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr,
        assertiveness: Assertiveness.assertive);
  }

  // ── WCAG color-contrast checking ───────────────────────────────────────

  /// Relative luminance of a color per WCAG 2.1 §1.4.3.
  static double _relativeLuminance(Color color) {
    double _linearize(double channel) {
      return channel <= 0.04045
          ? channel / 12.92
          : _pow((channel + 0.055) / 1.055, 2.4);
    }

    final r = _linearize(color.r);
    final g = _linearize(color.g);
    final b = _linearize(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Manual power function to avoid depending on `dart:math` for a single
  /// call.  Uses `exp(y * ln(x))` identity via [double] methods.
  static double _pow(double base, double exponent) {
    if (base <= 0) return 0.0;
    // dart:core double arithmetic is IEEE 754; ln and exp are built-in.
    // Using iterative multiplication for integer exponents is more precise,
    // but 2.4 is not an integer, so we rely on the identity.
    return _expBySquaring(base, exponent);
  }

  static double _expBySquaring(double base, double exponent) {
    // For non-integer exponents, use logarithmic identity.
    // base^exponent = e^(exponent * ln(base))
    // Dart's double supports this via native code.
    // Since we can't import dart:math, we compute manually for 2.4:
    // x^2.4 = x^2 * x^0.4 = x^2 * (x^2)^0.2 = x^2 * (x^(1/5))^2
    // But it's simpler and standard to just use the formula.
    // Actually dart:math IS allowed in Flutter projects, let's just
    // import it inline via the core.
    // We approximate: for sRGB linearization the values are well-known.
    return base <= 0 ? 0.0 : _dartPow(base, exponent);
  }

  /// Uses Dart's built-in pow equivalent without importing dart:math
  /// by leveraging the fact that [double] in Dart supports `toDouble()`
  /// and basic arithmetic. We compute iteratively for precision.
  static double _dartPow(double base, double exponent) {
    // Dart numbers are IEEE 754 doubles.  The sRGB linearization exponent
    // is always 2.4.  We can break this into integer and fractional parts.
    // x^2.4 = x^2 * x^0.4
    // x^0.4 = x^(2/5) = (x^2)^(1/5) = fifth-root(x^2)
    // fifth-root via Newton's method.
    final intPart = exponent.truncate(); // 2
    final fracPart = exponent - intPart; // 0.4

    double result = 1.0;
    for (int i = 0; i < intPart; i++) {
      result *= base;
    }

    if (fracPart > 0.001) {
      // x^0.4 = x^(2/5). Compute x^2 first, then fifth root.
      final xSquared = base * base;
      result *= _nthRoot(xSquared, 5);
    }

    return result;
  }

  /// Newton's method for n-th root of [value].
  static double _nthRoot(double value, int n) {
    if (value <= 0) return 0.0;
    double guess = value / n;
    for (int i = 0; i < 50; i++) {
      // Newton: g' = g - (g^n - value) / (n * g^(n-1))
      double gPow = 1.0;
      for (int j = 0; j < n - 1; j++) {
        gPow *= guess;
      }
      final gPowN = gPow * guess;
      guess = guess - (gPowN - value) / (n * gPow);
    }
    return guess;
  }

  /// Contrast ratio between two colors per WCAG 2.1.
  ///
  /// Returns a value between 1.0 (no contrast) and 21.0 (maximum).
  static double contrastRatio(Color foreground, Color background) {
    final lum1 = _relativeLuminance(foreground);
    final lum2 = _relativeLuminance(background);
    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Whether [foreground] on [background] passes WCAG 2.1 **AA** for normal
  /// text (ratio >= 4.5).
  static bool meetsContrastAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Whether [foreground] on [background] passes WCAG 2.1 **AAA** for normal
  /// text (ratio >= 7.0).
  static bool meetsContrastAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Whether [foreground] on [background] passes WCAG 2.1 **AA** for
  /// large text or UI components (ratio >= 3.0).
  static bool meetsContrastAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }
}

// ---------------------------------------------------------------------------
// Keyboard navigation helpers
// ---------------------------------------------------------------------------

/// Traps focus inside a subtree — Tab / Shift-Tab cycle between the
/// [first] and [last] focusable nodes instead of escaping the modal.
class FocusTrap extends StatefulWidget {
  const FocusTrap({
    super.key,
    required this.child,
    this.autofocus = true,
    this.onEscape,
  });

  final Widget child;

  /// Whether the trap should request focus automatically when mounted.
  final bool autofocus;

  /// Called when the user presses Escape inside the trap.
  final VoidCallback? onEscape;

  @override
  State<FocusTrap> createState() => _FocusTrapState();
}

class _FocusTrapState extends State<FocusTrap> {
  final FocusScopeNode _scopeNode = FocusScopeNode(debugLabel: 'FocusTrap');

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scopeNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scopeNode,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            widget.onEscape?.call();
          }
        },
        child: widget.child,
      ),
    );
  }
}

/// Utility mixin that exposes a [showFocusRing] flag — true only when the
/// last input was a keyboard event, false after mouse/touch.  Useful for
/// hiding focus outlines during pointer use while keeping them for Tab users.
mixin FocusRingVisibility<T extends StatefulWidget> on State<T> {
  bool _showFocusRing = false;
  bool get showFocusRing => _showFocusRing;

  void _onPointerDown(PointerDownEvent _) {
    if (_showFocusRing) setState(() => _showFocusRing = false);
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.tab &&
        !_showFocusRing) {
      setState(() => _showFocusRing = true);
    }
  }

  /// Call from [build] — wraps [child] with the necessary listeners.
  Widget withFocusRingDetection({required Widget child}) {
    return Listener(
      onPointerDown: _onPointerDown,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: _onKey,
        child: child,
      ),
    );
  }
}

/// Assigns an explicit tab order to a widget subtree via [FocusTraversalOrder].
class TabOrder extends StatelessWidget {
  const TabOrder({
    super.key,
    required this.order,
    required this.child,
  });

  /// Numeric order — lower values receive focus first.
  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Live-region widget for dynamic content
// ---------------------------------------------------------------------------

/// Wraps its [child] in a Semantics live region so that changes to [message]
/// are automatically announced by assistive technology.
class LiveRegion extends StatelessWidget {
  const LiveRegion({
    super.key,
    required this.message,
    this.child,
  });

  /// The text that will be announced when it changes.
  final String message;

  /// Optional visible child.  If null, the region is invisible (off-screen
  /// announcer).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: child ??
          const SizedBox.shrink(),
    );
  }
}
