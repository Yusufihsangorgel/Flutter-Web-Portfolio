part of 'contribution_event_order_lab.dart';

class _HorizontalSequence extends StatelessWidget {
  const _HorizontalSequence({required this.data, required this.accent});

  final _EventSequenceData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < data.sequence.order.length; index++) {
      final event = data.lab.eventById(data.sequence.order[index]);
      children.add(
        Expanded(
          child: _EventNode(
            event: event,
            progress: (
              step: index + 1,
              total: data.sequence.order.length,
              visible: index < data.visibleCount,
            ),
            accent: accent,
            reducedMotion: data.reducedMotion,
          ),
        ),
      );
      if (index < data.sequence.order.length - 1) {
        children.add(
          _SequenceLink(
            gap: _gapAfter(data.sequence, event.id),
            accent: accent,
            vertical: false,
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _VerticalSequence extends StatelessWidget {
  const _VerticalSequence({required this.data, required this.accent});

  final _EventSequenceData data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < data.sequence.order.length; index++) {
      final event = data.lab.eventById(data.sequence.order[index]);
      children.add(
        _EventNode(
          event: event,
          progress: (
            step: index + 1,
            total: data.sequence.order.length,
            visible: index < data.visibleCount,
          ),
          accent: accent,
          reducedMotion: data.reducedMotion,
        ),
      );
      if (index < data.sequence.order.length - 1) {
        children.add(
          _SequenceLink(
            gap: _gapAfter(data.sequence, event.id),
            accent: accent,
            vertical: true,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

PortfolioEventGap? _gapAfter(PortfolioEventSequence sequence, String eventId) =>
    sequence.gap?.after == eventId ? sequence.gap : null;

class _EventNode extends StatelessWidget {
  const _EventNode({
    required this.event,
    required this.progress,
    required this.accent,
    required this.reducedMotion,
  });

  final PortfolioEventOrderItem event;
  final _EventProgress progress;
  final Color accent;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final quiet = AppColors.white.withValues(alpha: 0.56);
    final border = progress.visible
        ? accent.withValues(alpha: 0.72)
        : AppColors.white.withValues(alpha: 0.13);
    final fill = progress.visible
        ? accent.withValues(alpha: 0.1)
        : AppColors.white.withValues(alpha: 0.025);

    return Semantics(
      label:
          '${context.strings.proofSectionEventLabStep} ${progress.step}/${progress.total}. ${event.label}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          key: ValueKey('event-lab-event-${event.id}'),
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 134),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
          ),
          child: _content(quiet),
        ),
      ),
    );
  }

  Widget _content(Color quiet) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        progress.step.toString().padLeft(2, '0'),
        style: AppFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: progress.visible ? accent : quiet,
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 20),
      Text(
        event.label,
        style: AppFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: progress.visible
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.5),
          height: 1.3,
        ),
      ),
      const SizedBox(height: 10),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          event.id,
          style: AppFonts.jetBrainsMono(fontSize: 9, color: quiet, height: 1.3),
        ),
      ),
    ],
  );
}

class _SequenceLink extends StatelessWidget {
  const _SequenceLink({
    required this.gap,
    required this.accent,
    required this.vertical,
  });

  final PortfolioEventGap? gap;
  final Color accent;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (gap != null) {
      return Semantics(
        label: '${context.strings.proofSectionEventLabRisk}: ${gap!.label}',
        child: ExcludeSemantics(
          child: Container(
            key: const Key('event-lab-risk-gap'),
            width: vertical ? double.infinity : 118,
            margin: vertical
                ? const EdgeInsets.symmetric(vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: SectionStyle.labRisk.withValues(alpha: 0.13),
              border: Border.all(
                color: SectionStyle.labRisk.withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              '${context.strings.proofSectionEventLabRisk}\n${gap!.label}',
              textAlign: TextAlign.center,
              style: AppFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: SectionStyle.labRiskText,
                height: 1.45,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: vertical ? double.infinity : 32,
      height: vertical ? 34 : 2,
      child: Center(
        child: Container(
          width: vertical ? 2 : double.infinity,
          height: vertical ? double.infinity : 2,
          color: accent.withValues(alpha: 0.48),
        ),
      ),
    );
  }
}
