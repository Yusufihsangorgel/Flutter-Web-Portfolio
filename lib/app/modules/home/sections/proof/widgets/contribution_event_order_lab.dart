import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/utils/motion_preference.dart';
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

import 'package:flutter_web_portfolio/app/features/language/application/language_context.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/section_style.dart';

part 'event_order_controls.dart';
part 'event_order_sequence.dart';

typedef _EventSequenceData = ({
  PortfolioEventOrderLab lab,
  PortfolioEventSequence sequence,
  int visibleCount,
  bool reducedMotion,
});
typedef _EventProgress = ({int step, int total, bool visible});

/// Replays content-authored event order without knowing the contribution.
class ContributionEventOrderLab extends StatefulWidget {
  const ContributionEventOrderLab({
    super.key,
    required this.lab,
    required this.accent,
  });

  final PortfolioEventOrderLab lab;
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
    final horizontal = MediaQuery.sizeOf(context).width >= 760;
    final signal = Color.lerp(widget.accent, AppColors.white, 0.55)!;
    return Container(
      key: const Key('contribution-event-order-lab'),
      padding: EdgeInsets.all(horizontal ? 34 : 22),
      decoration: BoxDecoration(
        color: SectionStyle.labSurface,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, signal),
          const SizedBox(height: 24),
          _controls(context, signal),
          const SizedBox(height: 28),
          _summary(context),
          const SizedBox(height: 28),
          _timeline(signal, horizontal),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Color signal) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.strings.proofSectionEventLabLabel.toUpperCase(),
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
            fontSize: MediaQuery.sizeOf(context).width >= 760 ? 31 : 26,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            height: 1.05,
            letterSpacing: -0.8,
          ),
        ),
      ),
    ],
  );

  Widget _controls(BuildContext context, Color signal) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _ScenarioControl(
        key: const Key('event-lab-without-patch'),
        action: (
          label: context.strings.proofSectionEventLabWithoutPatch,
          selected: !_patched,
          onTap: () => _selectSequence(false),
        ),
        accent: signal,
      ),
      _ScenarioControl(
        key: const Key('event-lab-with-patch'),
        action: (
          label: context.strings.proofSectionEventLabWithPatch,
          selected: _patched,
          onTap: () => _selectSequence(true),
        ),
        accent: signal,
      ),
      _ReplayControl(
        label: context.strings.proofSectionEventLabReplay,
        accent: signal,
        onTap: _replay,
      ),
    ],
  );

  Widget _summary(BuildContext context) => Semantics(
    liveRegion: true,
    label:
        '${context.strings.proofSectionEventLabSequence}: ${_sequence.summary}',
    child: ExcludeSemantics(
      child: Text(
        _sequence.summary,
        style: AppFonts.inter(
          fontSize: 14,
          color: AppColors.white.withValues(alpha: 0.62),
          height: 1.55,
        ),
      ),
    ),
  );

  Widget _timeline(Color signal, bool horizontal) {
    final data = (
      lab: widget.lab,
      sequence: _sequence,
      visibleCount: _visibleCount,
      reducedMotion: _reducedMotion,
    );
    return horizontal
        ? _HorizontalSequence(data: data, accent: signal)
        : _VerticalSequence(data: data, accent: signal);
  }
}
