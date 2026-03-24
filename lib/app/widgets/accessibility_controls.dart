import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/utils/accessibility_utils.dart';

// ---------------------------------------------------------------------------
// Keys used by SharedPreferences to persist user choices.
// ---------------------------------------------------------------------------
class _PrefKeys {
  static const fontScale = 'a11y_font_scale';
  static const reduceMotion = 'a11y_reduce_motion';
  static const highContrast = 'a11y_high_contrast';
  static const screenReaderMode = 'a11y_screen_reader_mode';
  static const showFocusIndicators = 'a11y_show_focus_indicators';
}

// ---------------------------------------------------------------------------
// Accessibility preferences — held in an InheritedWidget so every
// descendant can read the current settings via AccessibilityPrefs.of(ctx).
// ---------------------------------------------------------------------------

/// Immutable snapshot of the user's accessibility preferences.
@immutable
class AccessibilitySettings {
  const AccessibilitySettings({
    this.fontScale = 1.0,
    this.reduceMotion = false,
    this.highContrast = false,
    this.screenReaderMode = false,
    this.showFocusIndicators = true,
  });

  /// Text scaling factor: 0.85 (small), 1.0 (medium), 1.15 (large),
  /// 1.3 (extra-large).
  final double fontScale;

  /// When true, all non-essential animations are suppressed.
  final bool reduceMotion;

  /// When true, increased contrast colors are used throughout the UI.
  final bool highContrast;

  /// When true, additional semantic labels are surfaced and decorative
  /// content is hidden from the accessibility tree.
  final bool screenReaderMode;

  /// When true, visible focus rings are always painted around the focused
  /// interactive element.
  final bool showFocusIndicators;

  AccessibilitySettings copyWith({
    double? fontScale,
    bool? reduceMotion,
    bool? highContrast,
    bool? screenReaderMode,
    bool? showFocusIndicators,
  }) {
    return AccessibilitySettings(
      fontScale: fontScale ?? this.fontScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      screenReaderMode: screenReaderMode ?? this.screenReaderMode,
      showFocusIndicators: showFocusIndicators ?? this.showFocusIndicators,
    );
  }
}

/// Inherited widget that exposes the current [AccessibilitySettings] to
/// the widget tree.
class AccessibilityPrefs extends InheritedWidget {
  const AccessibilityPrefs({
    super.key,
    required this.settings,
    required super.child,
  });

  final AccessibilitySettings settings;

  /// Obtain the nearest [AccessibilitySettings] or fall back to defaults.
  static AccessibilitySettings of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<AccessibilityPrefs>();
    return widget?.settings ?? const AccessibilitySettings();
  }

  @override
  bool updateShouldNotify(AccessibilityPrefs oldWidget) =>
      settings != oldWidget.settings;
}

// ---------------------------------------------------------------------------
// AccessibilityPanel — the user-facing control surface.
// ---------------------------------------------------------------------------

/// An openable side-panel that lets users adjust font size, motion,
/// contrast, screen-reader friendliness, and focus indicator visibility.
///
/// Usage:
/// ```dart
/// IconButton(
///   icon: const Icon(Icons.accessibility_new),
///   tooltip: 'Accessibility settings',
///   onPressed: () => showAccessibilityPanel(context),
/// )
/// ```
Future<void> showAccessibilityPanel(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close accessibility panel',
    barrierColor: Colors.black54,
    transitionDuration: AccessibilityUtils.shouldReduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 300),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return const _AccessibilityPanelDialog();
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      if (AccessibilityUtils.shouldReduceMotion(ctx)) return child;
      final slide =
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(position: slide, child: child);
    },
  );
}

class _AccessibilityPanelDialog extends StatefulWidget {
  const _AccessibilityPanelDialog();

  @override
  State<_AccessibilityPanelDialog> createState() =>
      _AccessibilityPanelDialogState();
}

class _AccessibilityPanelDialogState extends State<_AccessibilityPanelDialog> {
  late AccessibilitySettings _settings;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _settings = AccessibilityPrefs.of(context);
      _loaded = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _settings = AccessibilitySettings(
        fontScale: prefs.getDouble(_PrefKeys.fontScale) ?? 1.0,
        reduceMotion: prefs.getBool(_PrefKeys.reduceMotion) ?? false,
        highContrast: prefs.getBool(_PrefKeys.highContrast) ?? false,
        screenReaderMode:
            prefs.getBool(_PrefKeys.screenReaderMode) ?? false,
        showFocusIndicators:
            prefs.getBool(_PrefKeys.showFocusIndicators) ?? true,
      );
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_PrefKeys.fontScale, _settings.fontScale),
      prefs.setBool(_PrefKeys.reduceMotion, _settings.reduceMotion),
      prefs.setBool(_PrefKeys.highContrast, _settings.highContrast),
      prefs.setBool(_PrefKeys.screenReaderMode, _settings.screenReaderMode),
      prefs.setBool(
          _PrefKeys.showFocusIndicators, _settings.showFocusIndicators),
    ]);
  }

  void _update(AccessibilitySettings updated) {
    setState(() => _settings = updated);
    _persist();
  }

  // ── Font scale helpers ──────────────────────────────────────────────────

  static const _fontScales = <double>[0.85, 1.0, 1.15, 1.3];
  static const _fontScaleLabels = <String>[
    'Small',
    'Medium',
    'Large',
    'Extra Large',
  ];

  int get _fontScaleIndex {
    final idx = _fontScales.indexOf(_settings.fontScale);
    return idx >= 0 ? idx : 1;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? AppColors.textBright : AppColors.lightTextBright;
    final subtitleColor =
        isDark ? AppColors.textPrimary : AppColors.lightTextSecondary;
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final reduceMotion =
        _settings.reduceMotion || AccessibilityUtils.shouldReduceMotion(context);
    final animDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return FocusTrap(
      onEscape: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: panelBg,
          elevation: 16,
          child: SizedBox(
            width: 360,
            height: double.infinity,
            child: SafeArea(
              child: Semantics(
                label: 'Accessibility settings panel',
                explicitChildNodes: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
                      child: Row(
                        children: [
                          Icon(Icons.accessibility_new,
                              color: AppColors.accent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Accessibility',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Semantics(
                            label: 'Close accessibility panel',
                            button: true,
                            child: IconButton(
                              icon: Icon(Icons.close, color: subtitleColor),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Close',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: dividerColor, height: 1),

                    // ── Scrollable settings ───────────────────────────
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        children: [
                          // Font size
                          _SectionTitle(
                            title: 'Text Size',
                            subtitle: _fontScaleLabels[_fontScaleIndex],
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label:
                                'Text size: ${_fontScaleLabels[_fontScaleIndex]}',
                            slider: true,
                            value: _fontScaleLabels[_fontScaleIndex],
                            child: Row(
                              children: List.generate(_fontScales.length, (i) {
                                final selected = i == _fontScaleIndex;
                                return Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(right: i < 3 ? 8 : 0),
                                    child: _ChoiceChipButton(
                                      label: _fontScaleLabels[i],
                                      selected: selected,
                                      animDuration: animDuration,
                                      onTap: () => _update(
                                        _settings.copyWith(
                                            fontScale: _fontScales[i]),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Preview
                          AnimatedDefaultTextStyle(
                            duration: animDuration,
                            style: TextStyle(
                              fontSize: 14 * _settings.fontScale,
                              color: subtitleColor,
                            ),
                            child: const Text(
                              'Preview: The quick brown fox jumps over the lazy dog.',
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Reduce motion
                          _ToggleTile(
                            icon: Icons.animation,
                            title: 'Reduce Motion',
                            subtitle:
                                'Minimise or disable all animations',
                            value: _settings.reduceMotion,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onChanged: (v) => _update(
                                _settings.copyWith(reduceMotion: v)),
                          ),
                          const SizedBox(height: 16),

                          // High contrast
                          _ToggleTile(
                            icon: Icons.contrast,
                            title: 'High Contrast',
                            subtitle:
                                'Increase colour contrast for readability',
                            value: _settings.highContrast,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onChanged: (v) => _update(
                                _settings.copyWith(highContrast: v)),
                          ),
                          const SizedBox(height: 16),

                          // Screen reader mode
                          _ToggleTile(
                            icon: Icons.record_voice_over,
                            title: 'Screen Reader Friendly',
                            subtitle:
                                'Expose extra labels, hide decorative content',
                            value: _settings.screenReaderMode,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onChanged: (v) => _update(
                                _settings.copyWith(screenReaderMode: v)),
                          ),
                          const SizedBox(height: 16),

                          // Focus indicators
                          _ToggleTile(
                            icon: Icons.center_focus_strong,
                            title: 'Focus Indicators',
                            subtitle:
                                'Always show visible focus rings on interactive elements',
                            value: _settings.showFocusIndicators,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onChanged: (v) => _update(
                                _settings.copyWith(showFocusIndicators: v)),
                          ),

                          const SizedBox(height: 32),

                          // Reset
                          Center(
                            child: Semantics(
                              label: 'Reset all accessibility settings to defaults',
                              button: true,
                              child: TextButton.icon(
                                icon: Icon(Icons.restore,
                                    color: subtitleColor, size: 18),
                                label: Text(
                                  'Reset to defaults',
                                  style: TextStyle(color: subtitleColor),
                                ),
                                onPressed: () {
                                  _update(const AccessibilitySettings());
                                  AccessibilityUtils.announcePolite(
                                      'Accessibility settings reset to defaults');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor)),
        const SizedBox(width: 8),
        Text('($subtitle)',
            style: TextStyle(fontSize: 12, color: subtitleColor)),
      ],
    );
  }
}

class _ChoiceChipButton extends StatelessWidget {
  const _ChoiceChipButton({
    required this.label,
    required this.selected,
    required this.animDuration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration animDuration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: '$label text size',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: animDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.accent
                  : (isDark
                      ? AppColors.textPrimary
                      : AppColors.lightTextSecondary),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.textColor,
    required this.subtitleColor,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color textColor;
  final Color subtitleColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '$title. $subtitle',
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.accent,
            onChanged: (v) {
              onChanged(v);
              AccessibilityUtils.announcePolite(
                  '$title ${v ? "enabled" : "disabled"}');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider widget — wraps the app and loads/applies persisted prefs.
// ---------------------------------------------------------------------------

/// Place this widget high in the tree (above MaterialApp) so that
/// [AccessibilityPrefs.of] is available everywhere.
///
/// ```dart
/// AccessibilityProvider(
///   child: MaterialApp(...),
/// )
/// ```
class AccessibilityProvider extends StatefulWidget {
  const AccessibilityProvider({super.key, required this.child});
  final Widget child;

  @override
  State<AccessibilityProvider> createState() => AccessibilityProviderState();

  /// Obtain the provider state from the tree to call [updateSettings].
  static AccessibilityProviderState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<AccessibilityProviderState>();
  }
}

class AccessibilityProviderState extends State<AccessibilityProvider> {
  AccessibilitySettings _settings = const AccessibilitySettings();

  AccessibilitySettings get settings => _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _settings = AccessibilitySettings(
        fontScale: prefs.getDouble(_PrefKeys.fontScale) ?? 1.0,
        reduceMotion: prefs.getBool(_PrefKeys.reduceMotion) ?? false,
        highContrast: prefs.getBool(_PrefKeys.highContrast) ?? false,
        screenReaderMode:
            prefs.getBool(_PrefKeys.screenReaderMode) ?? false,
        showFocusIndicators:
            prefs.getBool(_PrefKeys.showFocusIndicators) ?? true,
      );
    });
  }

  void updateSettings(AccessibilitySettings updated) {
    setState(() => _settings = updated);
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilityPrefs(
      settings: _settings,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(_settings.fontScale),
          disableAnimations: _settings.reduceMotion,
          highContrast: _settings.highContrast,
        ),
        child: widget.child,
      ),
    );
  }
}
