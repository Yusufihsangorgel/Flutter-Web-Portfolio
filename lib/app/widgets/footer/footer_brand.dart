part of '../premium_footer.dart';

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({this.centered = false});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final language = context.read<LanguageCubit>();

    return BlocBuilder<LanguageCubit, LanguageState>(
      buildWhen: (previous, current) =>
          previous.languageCode != current.languageCode ||
          !identical(previous.translations, current.translations),
      builder: (context, state) {
        final data =
            language.cvData['personal_info'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final name = (data['name'] as String?) ?? 'Senior Flutter Engineer';
        final year = DateTime.now().year;

        return Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: AppFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              language.getText(
                'cv_data.personal_info.tagline',
                defaultValue: 'Product-minded Flutter engineering',
              ),
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: AppFonts.jetBrainsMono(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '\u00A9 $year $name',
              style: AppFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}
