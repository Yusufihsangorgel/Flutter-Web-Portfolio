import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

@immutable
final class ContributionEventOrderLabLabels {
  const ContributionEventOrderLabLabels({
    required this.eyebrow,
    required this.withoutPatch,
    required this.withPatch,
    required this.replay,
    required this.sequence,
    required this.risk,
    required this.step,
  });

  final String eyebrow;
  final String withoutPatch;
  final String withPatch;
  final String replay;
  final String sequence;
  final String risk;
  final String step;
}

/// Replays content-authored event order without knowing the contribution.
class ContributionEventOrderLab extends StatefulWidget {
  const ContributionEventOrderLab({
    super.key,
    required this.lab,
    required this.labels,
    required this.accent,
  });

  final PortfolioEventOrderLab lab;
  final ContributionEventOrderLabLabels labels;
  final Color accent;

  @override
  State<ContributionEventOrderLab> createState() =>
      _ContributionEventOrderLabState();
}

class _ContributionEventOrderLabState extends State<ContributionEventOrderLab> {
  static const _stepDuration = Duration(milliseconds: 440);

  Timer? _replayTimer;
  bool _patched = false;
  bool _reducedMotion = false;
  late int _visibleCount;

  PortfolioEventSequence get _sequence =>
      _patched ? widget.lab.withPatch : widget.lab.baseline;

  @override
  void initState() {
    super.initState();
    _visibleCount = widget.lab.baseline.order.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reducedMotion = prefersReducedMotion(context);
    if (_reducedMotion == reducedMotion) return;
    _reducedMotion = reducedMotion;
    if (reducedMotion) {
      _replayTimer?.cancel();
      _visibleCount = _sequence.order.length;
    }
  }

  @override
  void didUpdateWidget(covariant ContributionEventOrderLab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lab == widget.lab) return;
    _replayTimer?.cancel();
    _patched = false;
    _visibleCount = widget.lab.baseline.order.length;
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }

  void _selectSequence(bool patched) {
    _replayTimer?.cancel();
    final sequence = patched ? widget.lab.withPatch : widget.lab.baseline;
    setState(() {
      _patched = patched;
      _visibleCount = _reducedMotion ? sequence.order.length : 1;
    });
    _continueReplay(sequence);
  }

  void _replay() {
    _replayTimer?.cancel();
    final sequence = _sequence;
    setState(() {
      _visibleCount = _reducedMotion ? sequence.order.length : 1;
    });
    _continueReplay(sequence);
  }

  void _continueReplay(PortfolioEventSequence sequence) {
    if (_reducedMotion || sequence.order.length <= 1) return;
    _replayTimer = Timer.periodic(_stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_visibleCount >= sequence.order.length) {
        timer.cancel();
        return;
      }
      final nextCount = _visibleCount + 1;
      setState(() => _visibleCount = nextCount);
      if (nextCount >= sequence.order.length) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sequence = _sequence;
    final isHorizontal = MediaQuery.sizeOf(context).width >= 760;
    const surface = Color(0xFF17191F);
    final quiet = AppColors.white.withValues(alpha: 0.62);
    final signal = Color.lerp(widget.accent, AppColors.white, 0.55)!;

    return Container(
      key: const Key('contribution-event-order-lab'),
      padding: EdgeInsets.all(isHorizontal ? 34 : 22),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labels.eyebrow.toUpperCase(),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: signal,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            headingLevel: 3,
            child: Text(
              widget.lab.title,
              style: AppFonts.spaceGrotesk(
                fontSize: isHorizontal ? 31 : 26,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                height: 1.05,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ScenarioControl(
                key: const Key('event-lab-without-patch'),
                label: widget.labels.withoutPatch,
                selected: !_patched,
                accent: signal,
                onTap: () => _selectSequence(false),
              ),
              _ScenarioControl(
                key: const Key('event-lab-with-patch'),
                label: widget.labels.withPatch,
                selected: _patched,
                accent: signal,
                onTap: () => _selectSequence(true),
              ),
              _ReplayControl(
                label: widget.labels.replay,
                accent: signal,
                onTap: _replay,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Semantics(
            liveRegion: true,
            label: '${widget.labels.sequence}: ${sequence.summary}',
            child: ExcludeSemantics(
              child: Text(
                sequence.summary,
                style: AppFonts.inter(fontSize: 14, color: quiet, height: 1.55),
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (isHorizontal)
            _HorizontalSequence(
              lab: widget.lab,
              sequence: sequence,
              visibleCount: _visibleCount,
              labels: widget.labels,
              accent: signal,
              reducedMotion: _reducedMotion,
            )
          else
            _VerticalSequence(
              lab: widget.lab,
              sequence: sequence,
              visibleCount: _visibleCount,
              labels: widget.labels,
              accent: signal,
              reducedMotion: _reducedMotion,
            ),
        ],
      ),
    );
  }
}

class _ScenarioControl extends StatelessWidget {
  const _ScenarioControl({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AccessibleAction(
    onTap: onTap,
    semanticLabel: label,
    selected: selected,
    focusColor: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            border: Border.all(
              color: selected
                  ? accent
                  : AppColors.white.withValues(alpha: 0.22),
            ),
          ),
          child: Text(
            label,
            style: AppFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF101114) : AppColors.white,
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

class _HorizontalSequence extends StatelessWidget {
  const _HorizontalSequence({
    required this.lab,
    required this.sequence,
    required this.visibleCount,
    required this.labels,
    required this.accent,
    required this.reducedMotion,
  });

  final PortfolioEventOrderLab lab;
  final PortfolioEventSequence sequence;
  final int visibleCount;
  final ContributionEventOrderLabLabels labels;
  final Color accent;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < sequence.order.length; index++) {
      final event = lab.eventById(sequence.order[index]);
      children.add(
        Expanded(
          child: _EventNode(
            event: event,
            step: index + 1,
            total: sequence.order.length,
            visible: index < visibleCount,
            labels: labels,
            accent: accent,
            reducedMotion: reducedMotion,
          ),
        ),
      );
      if (index < sequence.order.length - 1) {
        children.add(
          _SequenceLink(
            gap: _gapAfter(sequence, event.id),
            labels: labels,
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
  const _VerticalSequence({
    required this.lab,
    required this.sequence,
    required this.visibleCount,
    required this.labels,
    required this.accent,
    required this.reducedMotion,
  });

  final PortfolioEventOrderLab lab;
  final PortfolioEventSequence sequence;
  final int visibleCount;
  final ContributionEventOrderLabLabels labels;
  final Color accent;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < sequence.order.length; index++) {
      final event = lab.eventById(sequence.order[index]);
      children.add(
        _EventNode(
          event: event,
          step: index + 1,
          total: sequence.order.length,
          visible: index < visibleCount,
          labels: labels,
          accent: accent,
          reducedMotion: reducedMotion,
        ),
      );
      if (index < sequence.order.length - 1) {
        children.add(
          _SequenceLink(
            gap: _gapAfter(sequence, event.id),
            labels: labels,
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
    required this.step,
    required this.total,
    required this.visible,
    required this.labels,
    required this.accent,
    required this.reducedMotion,
  });

  final PortfolioEventOrderItem event;
  final int step;
  final int total;
  final bool visible;
  final ContributionEventOrderLabLabels labels;
  final Color accent;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final quiet = AppColors.white.withValues(alpha: 0.56);
    final border = visible
        ? accent.withValues(alpha: 0.72)
        : AppColors.white.withValues(alpha: 0.13);
    final fill = visible
        ? accent.withValues(alpha: 0.1)
        : AppColors.white.withValues(alpha: 0.025);

    return Semantics(
      label: '${labels.step} $step/$total. ${event.label}',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step.toString().padLeft(2, '0'),
                style: AppFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: visible ? accent : quiet,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 20),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  event.label,
                  style: AppFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: visible
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.5),
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  event.id,
                  style: AppFonts.jetBrainsMono(
                    fontSize: 9,
                    color: quiet,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SequenceLink extends StatelessWidget {
  const _SequenceLink({
    required this.gap,
    required this.labels,
    required this.accent,
    required this.vertical,
  });

  final PortfolioEventGap? gap;
  final ContributionEventOrderLabLabels labels;
  final Color accent;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (gap != null) {
      return Semantics(
        label: '${labels.risk}: ${gap!.label}',
        child: ExcludeSemantics(
          child: Container(
            key: const Key('event-lab-risk-gap'),
            width: vertical ? double.infinity : 118,
            margin: vertical
                ? const EdgeInsets.symmetric(vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF725C).withValues(alpha: 0.13),
              border: Border.all(
                color: const Color(0xFFFF725C).withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              '${labels.risk}\n${gap!.label}',
              textAlign: TextAlign.center,
              style: AppFonts.jetBrainsMono(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF9B8B),
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
