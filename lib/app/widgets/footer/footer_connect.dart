part of '../premium_footer.dart';

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
            languageController.getText('footer.connect', defaultValue: 'Connect'),
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

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

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
    if (email.isEmpty || !_emailRegex.hasMatch(email)) return;

    if (Get.isRegistered<SoundController>()) {
      Get.find<SoundController>().playSuccess();
    }
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
          Get.find<LanguageController>().getText('footer.stay_updated', defaultValue: 'Stay Updated'),
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
                          Get.find<LanguageController>().getText('footer.subscribed', defaultValue: 'Subscribed!'),
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
                          color: secondaryColor.withValues(alpha: 0.75),
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
