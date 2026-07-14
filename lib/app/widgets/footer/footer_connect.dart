part of '../premium_footer.dart';

// =============================================================================
// Right column: configured public links or a truthful verification note
// =============================================================================

class _ConnectColumn extends StatelessWidget {
  const _ConnectColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final languageController = context.read<LanguageCubit>();

    return BlocBuilder<LanguageCubit, LanguageState>(
      buildWhen: (previous, current) =>
          previous.languageCode != current.languageCode ||
          !identical(previous.translations, current.translations),
      builder: (context, state) {
        final data =
            languageController.cvData['personal_info']
                as Map<String, dynamic>? ??
            <String, dynamic>{};
        final email = (data['email'] as String?) ?? '';
        final links = <SocialLinkData>[
          if ((data['github'] as String? ?? '').isNotEmpty)
            SocialPresets.github(data['github'] as String),
          if ((data['linkedin'] as String? ?? '').isNotEmpty)
            SocialPresets.linkedin(data['linkedin'] as String),
          if ((data['twitter'] as String? ?? '').isNotEmpty)
            SocialPresets.twitter(data['twitter'] as String),
          if ((data['medium'] as String? ?? '').isNotEmpty)
            SocialPresets.medium(data['medium'] as String),
          if (email.isNotEmpty) SocialPresets.email(email),
        ];
        final hasPublicContact = links.isNotEmpty;

        return Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasPublicContact
                  ? languageController.getText(
                      'footer.connect',
                      defaultValue: 'Connect',
                    )
                  : 'Verification',
              style: AppFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (hasPublicContact) ...[
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
                _EmailLink(email: email),
              ],
            ] else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Runtime, renderer, isolation, and frame timing evidence '
                  'are inspectable directly from this page.',
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmailLink extends StatefulWidget {
  const _EmailLink({required this.email});

  final String email;

  @override
  State<_EmailLink> createState() => _EmailLinkState();
}

class _EmailLinkState extends State<_EmailLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
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
        style: AppFonts.jetBrainsMono(
          fontSize: 12,
          color: _hovered ? AppColors.accent : AppColors.textSecondary,
          decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
          decorationColor: AppColors.accent.withValues(alpha: 0.5),
        ),
      ),
    ),
  );
}
