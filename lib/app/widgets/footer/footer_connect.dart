part of '../premium_footer.dart';

// =============================================================================
// Right column: current professional focus
// =============================================================================

class _ConnectColumn extends StatelessWidget {
  const _ConnectColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        buildWhen: (previous, current) =>
            previous.languageCode != current.languageCode ||
            !identical(previous.translations, current.translations),
        builder: (context, state) {
          final language = context.read<LanguageCubit>();

          return Column(
            crossAxisAlignment: centered
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.getText(
                  'footer.verification',
                  defaultValue: 'Current focus',
                ),
                style: AppFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  language.getText(
                    'footer.verification_body',
                    defaultValue:
                        'Building thoughtful Flutter products and the Go '
                        'services behind them.',
                  ),
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
