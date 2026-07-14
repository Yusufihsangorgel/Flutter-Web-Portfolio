import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocProvider;
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/constants/scene_configs.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/domain/frame_statistics.dart';
import 'package:flutter_web_portfolio/app/features/engineering_lab/domain/runtime_profile.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';

/// An inspectable, truthful view of the Flutter Web runtime behind the site.
class EngineeringLab extends StatefulWidget {
  const EngineeringLab({
    required this.localeCount,
    required this.currentLocale,
    this.activeSection = 'home',
    super.key,
  });

  final int localeCount;
  final String currentLocale;
  final String activeSection;

  static Future<void> show(
    BuildContext context, {
    String activeSection = 'home',
  }) {
    final languageCubit = BlocProvider.of<LanguageCubit>(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Engineering Lab',
      barrierColor: Colors.black.withValues(alpha: 0.76),
      transitionDuration: reduceMotion ? Duration.zero : AppDurations.medium,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: CinematicCurves.dramaticEntrance,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (_, _, _) => EngineeringLab(
        localeCount: languageCubit.supportedLanguages.length,
        currentLocale: languageCubit.currentLanguage,
        activeSection: activeSection,
      ),
    );
  }

  @override
  State<EngineeringLab> createState() => _EngineeringLabState();
}

class _EngineeringLabState extends State<EngineeringLab> {
  late final RuntimeProfile _runtimeProfile;
  final List<FrameTiming> _timings = [];

  @override
  void initState() {
    super.initState();
    _runtimeProfile = RuntimeProfile.current();
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    setState(() {
      _timings.addAll(timings);
      if (_timings.length > 120) {
        _timings.removeRange(0, _timings.length - 120);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 760;

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 960,
              maxHeight: math.min(screenSize.height * 0.9, 820),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(isCompact ? 20 : 28),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        blurRadius: 80,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 20 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(onClose: () => Navigator.of(context).pop()),
                        const SizedBox(height: 24),
                        _RuntimeStrip(profile: _runtimeProfile),
                        const SizedBox(height: 16),
                        if (isCompact) ...[
                          _FrameTrace(timings: _timings),
                          const SizedBox(height: 16),
                          _ArchitectureCard(
                            localeCount: widget.localeCount,
                            currentLocale: widget.currentLocale,
                            activeSection: widget.activeSection,
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _FrameTrace(timings: _timings),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 5,
                                child: _ArchitectureCard(
                                  localeCount: widget.localeCount,
                                  currentLocale: widget.currentLocale,
                                  activeSection: widget.activeSection,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        const _ScenePipeline(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ENGINEERING LAB / LIVE',
              style: _mono(
                fontSize: 11,
                color: AppColors.accent,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inspect the page while it runs',
              style: AppFonts.spaceGrotesk(
                fontSize: 28,
                height: 1.05,
                color: AppColors.textBright,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'These values come from this browser session—not a benchmark screenshot.',
              style: AppFonts.spaceGrotesk(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      Semantics(
        button: true,
        label: 'Close Engineering Lab',
        child: IconButton(
          tooltip: 'Close Engineering Lab',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}

class _RuntimeStrip extends StatelessWidget {
  const _RuntimeStrip({required this.profile});

  final RuntimeProfile profile;

  @override
  Widget build(BuildContext context) => _LabCard(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _RuntimeFact(
          label: 'RUNTIME',
          value: profile.runtime,
          indicatorColor: const Color(0xFF7CFFB2),
        ),
        _RuntimeFact(label: 'RENDERER', value: profile.renderer),
        _RuntimeFact(label: 'ACTIVE ARTIFACT', value: profile.artifact),
        _RuntimeFact(
          label: 'CROSS-ORIGIN ISOLATION',
          value: profile.crossOriginIsolated ? 'Active' : 'Unavailable',
          indicatorColor: profile.crossOriginIsolated
              ? const Color(0xFF7CFFB2)
              : const Color(0xFFFFC76B),
        ),
        if (profile.logicalProcessors case final int count)
          _RuntimeFact(label: 'LOGICAL PROCESSORS', value: '$count reported'),
      ],
    ),
  );
}

class _RuntimeFact extends StatelessWidget {
  const _RuntimeFact({
    required this.label,
    required this.value,
    this.indicatorColor = AppColors.accent,
  });

  final String label;
  final String value;
  final Color indicatorColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: indicatorColor, blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _labelStyle),
            const SizedBox(height: 2),
            Text(value, style: _valueStyle),
          ],
        ),
      ],
    ),
  );
}

class _FrameTrace extends StatelessWidget {
  const _FrameTrace({required this.timings});

  final List<FrameTiming> timings;

  @override
  Widget build(BuildContext context) {
    final total = FrameStatistics.fromDurations(
      timings.map((timing) => timing.totalSpan),
    );
    final build = FrameStatistics.fromDurations(
      timings.map((timing) => timing.buildDuration),
    );
    final raster = FrameStatistics.fromDurations(
      timings.map((timing) => timing.rasterDuration),
    );
    final chartValues = timings
        .map((timing) => timing.totalSpan.inMicroseconds / 1000)
        .toList(growable: false);
    final hasStableWindow = total.sampleCount >= 30;

    return _LabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
            eyebrow: 'LIVE FRAME TRACE',
            title: 'Flutter scheduler telemetry',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 92,
            width: double.infinity,
            child: CustomPaint(
              painter: _FrameChartPainter(samples: chartValues),
            ),
          ),
          const SizedBox(height: 14),
          if (!hasStableWindow)
            Text(
              'Collecting a stable frame window… ${total.sampleCount}/30',
              style: _valueStyle.copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _Metric(label: 'TOTAL P50', value: total.medianMilliseconds),
                _Metric(label: 'TOTAL P95', value: total.p95Milliseconds),
                _Metric(label: 'BUILD P50', value: build.medianMilliseconds),
                _Metric(label: 'RASTER P50', value: raster.medianMilliseconds),
              ],
            ),
          const SizedBox(height: 12),
          Text(
            '${total.sampleCount} rolling samples · milliseconds · current session only',
            style: _mono(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _labelStyle),
      const SizedBox(height: 3),
      Text(
        value.toStringAsFixed(1),
        style: _mono(
          fontSize: 20,
          color: AppColors.textBright,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ArchitectureCard extends StatelessWidget {
  const _ArchitectureCard({
    required this.localeCount,
    required this.currentLocale,
    required this.activeSection,
  });

  final int localeCount;
  final String currentLocale;
  final String activeSection;

  @override
  Widget build(BuildContext context) => _LabCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardTitle(
          eyebrow: 'IMPLEMENTATION',
          title: 'What is actually running',
        ),
        const SizedBox(height: 18),
        _ArchitectureRow(
          value: '${SceneConfigs.scenes.length}',
          label: 'scroll-driven scenes',
        ),
        _ArchitectureRow(
          value: '$localeCount',
          label: 'locale documents · $currentLocale active',
        ),
        const _ArchitectureRow(
          value: 'O(n)',
          label: 'particle neighbour lookup via spatial grid',
        ),
        const _ArchitectureRow(
          value: '1',
          label: 'HTML boot/recovery surface · product UI in Flutter',
        ),
        _ArchitectureRow(
          value: '#/$activeSection',
          label: 'section synchronized with browser history',
        ),
      ],
    ),
  );
}

class _ArchitectureRow extends StatelessWidget {
  const _ArchitectureRow({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            value,
            style: _mono(
              fontSize: 14,
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: AppFonts.spaceGrotesk(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScenePipeline extends StatelessWidget {
  const _ScenePipeline();

  @override
  Widget build(BuildContext context) => _LabCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CardTitle(
          eyebrow: 'RENDER PIPELINE',
          title: 'One canvas, five reactive visual systems',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final cards = <Widget>[
              for (var i = 0; i < SceneConfigs.scenes.length; i++)
                _SceneNode(index: i, config: SceneConfigs.scenes[i]),
            ];
            return compact
                ? Wrap(spacing: 8, runSpacing: 8, children: cards)
                : Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  );
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Scroll position drives scene interpolation, gradients, particle velocity, accents, and vignette intensity.',
          style: AppFonts.spaceGrotesk(
            fontSize: 12,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _SceneNode extends StatelessWidget {
  const _SceneNode({required this.index, required this.config});

  final int index;
  final SceneConfig config;

  static const _names = ['HERO', 'ABOUT', 'EXPERIENCE', 'PROOF', 'PROJECTS'];

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          config.gradient1.withValues(alpha: 0.42),
          config.gradient2.withValues(alpha: 0.18),
        ],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: config.accent.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '0${index + 1}',
          style: _labelStyle.copyWith(color: config.accent),
        ),
        const SizedBox(height: 8),
        Text(
          _names[index],
          overflow: TextOverflow.ellipsis,
          style: _mono(
            fontSize: 10,
            color: AppColors.textBright,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(eyebrow, style: _labelStyle.copyWith(color: AppColors.accent)),
      const SizedBox(height: 5),
      Text(
        title,
        style: AppFonts.spaceGrotesk(
          fontSize: 17,
          color: AppColors.textBright,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: child,
  );
}

class _FrameChartPainter extends CustomPainter {
  const _FrameChartPainter({required this.samples});

  final List<double> samples;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final budgetY = size.height * (1 - 16.67 / 50);
    canvas.drawLine(
      Offset(0, budgetY.clamp(0, size.height)),
      Offset(size.width, budgetY.clamp(0, size.height)),
      gridPaint,
    );

    if (samples.length < 2) return;

    final visible = samples.length > 80
        ? samples.sublist(samples.length - 80)
        : samples;
    const ceiling = 50.0;
    final path = Path();
    for (var i = 0; i < visible.length; i++) {
      final x = size.width * i / (visible.length - 1);
      final normalized = (visible[i] / ceiling).clamp(0.0, 1.0);
      final y = size.height * (1 - normalized);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.16)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4DFFF3), Color(0xFF8E7CFF)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, glowPaint)
      ..drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_FrameChartPainter oldDelegate) =>
      !listEquals(oldDelegate.samples, samples);
}

TextStyle _mono({
  required double fontSize,
  required Color color,
  double? letterSpacing,
  FontWeight? fontWeight,
}) => AppFonts.jetBrainsMono(
  fontSize: fontSize,
  color: color,
  letterSpacing: letterSpacing,
  fontWeight: fontWeight,
);

final _labelStyle = _mono(
  fontSize: 9,
  color: AppColors.textSecondary,
  letterSpacing: 1.1,
  fontWeight: FontWeight.w600,
);

final _valueStyle = AppFonts.spaceGrotesk(
  fontSize: 12,
  color: AppColors.textBright,
  fontWeight: FontWeight.w500,
);
