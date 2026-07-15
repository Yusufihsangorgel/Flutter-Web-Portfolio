part of '../premium_footer.dart';

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
    ),
    child: const Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 10,
      children: [_BuiltWithFlutter(), _CommandPaletteHint()],
    ),
  );
}

class _BuiltWithFlutter extends StatelessWidget {
  const _BuiltWithFlutter();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const FlutterLogo(size: 13, style: FlutterLogoStyle.markOnly),
      const SizedBox(width: 7),
      Text(
        'Built with Flutter',
        style: AppFonts.jetBrainsMono(
          fontSize: 11,
          color: AppColors.textSecondary.withValues(alpha: 0.62),
        ),
      ),
    ],
  );
}

class _CommandPaletteHint extends StatelessWidget {
  const _CommandPaletteHint();

  @override
  Widget build(BuildContext context) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final shortcut = isMac ? '\u2318K' : 'Ctrl+K';
    final language = context.read<LanguageCubit>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${language.getText('footer.command_hint_prefix', defaultValue: 'Press')} ',
          style: AppFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            shortcut,
            style: AppFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textSecondary.withValues(alpha: 0.72),
            ),
          ),
        ),
        Text(
          ' ${language.getText('footer.command_hint_suffix', defaultValue: 'to open command palette')}',
          style: AppFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
