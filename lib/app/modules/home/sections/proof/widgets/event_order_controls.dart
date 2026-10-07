part of 'contribution_event_order_lab.dart';

class _ScenarioControl extends StatelessWidget {
  const _ScenarioControl({
    super.key,
    required this.action,
    required this.accent,
  });

  final ({String label, bool selected, VoidCallback onTap}) action;
  final Color accent;

  @override
  Widget build(BuildContext context) => AccessibleAction(
    onTap: action.onTap,
    semanticLabel: action.label,
    selected: action.selected,
    focusColor: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: action.selected ? accent : Colors.transparent,
            border: Border.all(
              color: action.selected
                  ? accent
                  : AppColors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            action.label,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: action.selected ? SectionStyle.labInk : AppColors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

class _ReplayControl extends StatelessWidget {
  const _ReplayControl({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AccessibleAction(
    key: const Key('event-lab-replay'),
    onTap: onTap,
    semanticLabel: label,
    focusColor: accent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, size: 17, color: accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
