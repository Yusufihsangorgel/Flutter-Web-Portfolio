import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/widgets/neon_effects.dart';
import 'package:flutter_web_portfolio/app/widgets/social_links_row.dart';

/// App version displayed in the footer.
const String _appVersion = '1.1.0';

// =============================================================================
// PremiumFooter
// =============================================================================

/// A full-width dark footer with an animated gradient neon top border,
/// three-column responsive layout (logo + tagline + copyright | quick links
/// with hover | social links + contact), newsletter subscription, animated
/// "Built with Flutter" heart badge, command palette hint, and a 5-click
/// easter egg on the copyright line.
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
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.04),
            ),
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
                child:
                    isDesktop ? const _DesktopLayout() : const _MobileLayout(),
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
        // Right — social icons + newsletter
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

// =============================================================================
// Left column: Logo, tagline, copyright with easter egg
// =============================================================================

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    const secondaryColor = AppColors.textSecondary;
    const brightColor = AppColors.textBright;

    return Obx(() {
      final data = languageController.cvData['personal_info']
              as Map<String, dynamic>? ??
          <String, dynamic>{};
      final name = (data['name'] as String?) ?? 'Your Name';

      return Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Neon name / logo ──────────────────────────────────────
          NeonText(
            text: name,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: brightColor,
            ),
            intensity: 0.6,
            blurRadius: 14,
            animated: true,
          ),
          const SizedBox(height: 12),

          // ── Tagline ───────────────────────────────────────────────
          Text(
            languageController.getText(
              'cv_data.personal_info.tagline',
              defaultValue: 'Building digital experiences',
            ),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: secondaryColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // ── Copyright with 5-click easter egg ─────────────────────
          _CopyrightEasterEgg(name: name, centered: centered),
        ],
      );
    });
  }
}

// =============================================================================
// Center column: Quick navigation links with hover effects
// =============================================================================

class _QuickLinksColumn extends StatelessWidget {
  const _QuickLinksColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    const brightColor = AppColors.textBright;

    const sections = <_QuickLinkItem>[
      _QuickLinkItem('home', 'Home'),
      _QuickLinkItem('about', 'About'),
      _QuickLinkItem('experience', 'Experience'),
      _QuickLinkItem('projects', 'Projects'),
      _QuickLinkItem('blog', 'Blog'),
      _QuickLinkItem('contact', 'Contact'),
    ];

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Quick Links',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: brightColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...sections.map((item) => _QuickLinkButton(
              sectionId: item.id,
              label: item.label,
              centered: centered,
            )),
      ],
    );
  }
}

class _QuickLinkItem {
  const _QuickLinkItem(this.id, this.label);
  final String id;
  final String label;
}

/// A single quick link with an expanding accent dash on hover.
class _QuickLinkButton extends StatefulWidget {
  const _QuickLinkButton({
    required this.sectionId,
    required this.label,
    this.centered = false,
  });

  final String sectionId;
  final String label;
  final bool centered;

  @override
  State<_QuickLinkButton> createState() => _QuickLinkButtonState();
}

class _QuickLinkButtonState extends State<_QuickLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Get.find<AppScrollController>().scrollToSection(widget.sectionId);
          },
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: CinematicCurves.hoverLift,
            transform: Matrix4.translationValues(
              _hovered && !widget.centered ? 6 : 0,
              0,
              0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expanding accent dash indicator
                AnimatedContainer(
                  duration: AppDurations.fast,
                  width: _hovered ? 20 : 0,
                  height: 1,
                  color: AppColors.accent.withValues(alpha: 0.6),
                ),
                if (_hovered) const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: _hovered ? AppColors.accent : baseColor,
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
// Right column: Social icons + Email + Newsletter
// =============================================================================

class _ConnectColumn extends StatelessWidget {
  const _ConnectColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    const brightColor = AppColors.textBright;

    return Obx(() {
      final data = languageController.cvData['personal_info']
              as Map<String, dynamic>? ??
          <String, dynamic>{};
      final github = (data['github'] as String?) ?? '';
      final linkedin = (data['linkedin'] as String?) ?? '';
      final email = (data['email'] as String?) ?? '';
      final twitter = (data['twitter'] as String?) ?? '';
      final medium = (data['medium'] as String?) ?? '';

      final links = <SocialLinkData>[
        if (github.isNotEmpty) SocialPresets.github(github),
        if (linkedin.isNotEmpty) SocialPresets.linkedin(linkedin),
        if (twitter.isNotEmpty) SocialPresets.twitter(twitter),
        if (medium.isNotEmpty) SocialPresets.medium(medium),
        if (email.isNotEmpty) SocialPresets.email(email),
      ];

      return Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Connect',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: brightColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Social icons with brand-color hover & magnetic effect
          if (links.isNotEmpty)
            SocialLinksRow(
              links: links,
              iconSize: 20,
              spacing: 8,
              alignment: centered
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
            ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 12),
            _EmailLink(email: email, centered: centered),
          ],
          const SizedBox(height: 24),

          // Newsletter subscription form
          _NewsletterSubscribe(centered: centered),
        ],
      );
    });
  }
}

// =============================================================================
// Email contact link with hover underline
// =============================================================================

class _EmailLink extends StatefulWidget {
  const _EmailLink({required this.email, this.centered = false});

  final String email;
  final bool centered;

  @override
  State<_EmailLink> createState() => _EmailLinkState();
}

class _EmailLinkState extends State<_EmailLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse('mailto:${widget.email}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Text(
          widget.email,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: _hovered ? AppColors.accent : baseColor,
            decoration:
                _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.accent.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Newsletter subscription widget
// =============================================================================

class _NewsletterSubscribe extends StatefulWidget {
  const _NewsletterSubscribe({this.centered = false});

  final bool centered;

  @override
  State<_NewsletterSubscribe> createState() => _NewsletterSubscribeState();
}

class _NewsletterSubscribeState extends State<_NewsletterSubscribe>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _subscribed = false;
  late final AnimationController _successCtrl;
  late final Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnimation = CurvedAnimation(
      parent: _successCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _subscribe() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _subscribed = true);
    _successCtrl.forward();
    _emailController.clear();

    // Reset after delay
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _successCtrl.reverse().then((_) {
          if (mounted) setState(() => _subscribed = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return Column(
      crossAxisAlignment: widget.centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Stay Updated',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (_subscribed)
          AnimatedBuilder(
            animation: _successAnimation,
            builder: (_, __) {
              final v = _successAnimation.value;
              return Opacity(
                opacity: v,
                child: Transform.scale(
                  scale: 0.8 + 0.2 * v,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.expAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.expAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Subscribed!',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppColors.expAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      onSubmitted: (_) => _subscribe(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.textBright,
                      ),
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: secondaryColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  _SubscribeButton(onTap: _subscribe),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  const _SubscribeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color:
                _hovered ? Colors.white : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
}

// =============================================================================
// Copyright with 5-click easter egg
// =============================================================================

class _CopyrightEasterEgg extends StatefulWidget {
  const _CopyrightEasterEgg({
    required this.name,
    this.centered = false,
  });

  final String name;
  final bool centered;

  @override
  State<_CopyrightEasterEgg> createState() => _CopyrightEasterEggState();
}

class _CopyrightEasterEggState extends State<_CopyrightEasterEgg>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  bool _easterEggVisible = false;
  late final AnimationController _eggCtrl;
  late final Animation<double> _eggAnimation;

  static const _easterEggMessages = <String>[
    'You found a secret! You must be a curious developer.',
    'This portfolio was built with passion and lots of coffee.',
    'Fun fact: the first version of this was 47 lines of code.',
    'Thanks for exploring every corner of this portfolio!',
    'You are awesome. Have an amazing day!',
  ];

  @override
  void initState() {
    super.initState();
    _eggCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _eggAnimation = CurvedAnimation(
      parent: _eggCtrl,
      curve: CinematicCurves.dramaticEntrance,
    );
  }

  @override
  void dispose() {
    _eggCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      setState(() => _easterEggVisible = true);
      _eggCtrl.forward(from: 0);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _eggCtrl.reverse().then((_) {
            if (mounted) setState(() => _easterEggVisible = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    const secondaryColor = AppColors.textSecondary;

    return Column(
      crossAxisAlignment: widget.centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _onTap,
          child: Text(
            '\u00A9 $year ${widget.name}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: secondaryColor,
            ),
          ),
        ),
        if (_easterEggVisible)
          AnimatedBuilder(
            animation: _eggAnimation,
            builder: (_, __) {
              final v = _eggAnimation.value;
              final message = _easterEggMessages[
                  DateTime.now().second % _easterEggMessages.length];
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - v)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        message,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// =============================================================================
// Bottom bar: Built with Flutter, version, powered by, command palette hint
// =============================================================================

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 8,
        children: [
          // "Built with Flutter & <3" with pulsing heart
          const _BuiltWithFlutter(),
          // Version label
          Text(
            'v$_appVersion',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          // Powered by Flutter with spinning logo on hover
          const _PoweredByFlutter(),
          // Command palette keyboard shortcut hint
          const _CommandPaletteHint(),
        ],
      ),
    );
  }
}

// =============================================================================
// "Built with Flutter & <3" with animated heart
// =============================================================================

class _BuiltWithFlutter extends StatefulWidget {
  const _BuiltWithFlutter();

  @override
  State<_BuiltWithFlutter> createState() => _BuiltWithFlutterState();
}

class _BuiltWithFlutterState extends State<_BuiltWithFlutter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Built with Flutter & ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.6),
          ),
        ),
        AnimatedBuilder(
          animation: _heartCtrl,
          builder: (_, __) {
            final scale =
                0.85 + 0.3 * math.sin(_heartCtrl.value * math.pi);
            return Transform.scale(
              scale: scale,
              child: const Text(
                '\u2764\uFE0F',
                style: TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// "Powered by Flutter" with spinning logo on hover
// =============================================================================

class _PoweredByFlutter extends StatefulWidget {
  const _PoweredByFlutter();

  @override
  State<_PoweredByFlutter> createState() => _PoweredByFlutterState();
}

class _PoweredByFlutterState extends State<_PoweredByFlutter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _spinCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) => _onHoverChanged(false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered by ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          AnimatedBuilder(
            animation: _spinCtrl,
            builder: (_, child) => Transform(
                alignment: Alignment.center,
                transform:
                    Matrix4.rotationY(_spinCtrl.value * 2 * math.pi),
                child: child,
              ),
            child: FlutterLogo(
              size: 14,
              style: FlutterLogoStyle.markOnly,
              textColor: _hovered
                  ? AppColors.accent
                  : secondaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'Flutter',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: _hovered
                  ? AppColors.accent
                  : secondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Command palette hint
// =============================================================================

class _CommandPaletteHint extends StatelessWidget {
  const _CommandPaletteHint();

  @override
  Widget build(BuildContext context) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final shortcut = isMac ? '\u2318K' : 'Ctrl+K';
    const secondaryColor = AppColors.textSecondary;
    final languageController = Get.find<LanguageController>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${languageController.getText('footer.command_hint_prefix', defaultValue: 'Press')} ',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color:
                Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            shortcut,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: secondaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          ' ${languageController.getText('footer.command_hint_suffix', defaultValue: 'to open command palette')}',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: secondaryColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
