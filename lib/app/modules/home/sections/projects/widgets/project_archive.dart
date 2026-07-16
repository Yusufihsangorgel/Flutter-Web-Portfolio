import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

/// A typographic project index with a content-driven desktop reading pane.
class ProjectArchive extends StatefulWidget {
  const ProjectArchive({super.key, required this.systems});

  final List<PortfolioSystem> systems;

  @override
  State<ProjectArchive> createState() => _ProjectArchiveState();
}

class _ProjectArchiveState extends State<ProjectArchive> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(ProjectArchive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.systems.length) {
      _activeIndex = math.max(0, widget.systems.length - 1);
    }
  }

  void _select(int index) {
    if (index == _activeIndex || !mounted) return;
    setState(() => _activeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.systems.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (!wide) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x33F2F0E9))),
            ),
            child: Column(
              children: [
                for (var index = 0; index < widget.systems.length; index++)
                  _ArchiveRow(
                    key: ValueKey(
                      'project-archive-${widget.systems[index].id}',
                    ),
                    system: widget.systems[index],
                    index: index,
                    active: false,
                    compact: true,
                    onSelected: () => _select(index),
                  ),
              ],
            ),
          );
        }

        final activeSystem = widget.systems[_activeIndex];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 12,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x33F2F0E9))),
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < widget.systems.length; index++)
                      _ArchiveRow(
                        key: ValueKey(
                          'project-archive-${widget.systems[index].id}',
                        ),
                        system: widget.systems[index],
                        index: index,
                        active: index == _activeIndex,
                        compact: false,
                        onSelected: () => _select(index),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 68),
            Expanded(
              flex: 8,
              child: ExcludeSemantics(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _ArchivePreview(
                    key: ValueKey('project-preview-${activeSystem.id}'),
                    system: activeSystem,
                    index: _activeIndex,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({
    super.key,
    required this.system,
    required this.index,
    required this.active,
    required this.compact,
    required this.onSelected,
  });

  final PortfolioSystem system;
  final int index;
  final bool active;
  final bool compact;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(system.url, webOnlyWindowName: '_blank'),
    onHoverChanged: (hovered) {
      if (hovered) onSelected();
    },
    onFocusChanged: (focused) {
      if (focused) onSelected();
    },
    semanticLabel: '${system.name}. ${system.kind}. ${system.summary}',
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: active && !compact ? 14 : 0,
          top: compact ? 26 : 23,
          bottom: compact ? 27 : 24,
        ),
        child: compact ? _compactContent() : _wideContent(),
      ),
    ),
  );

  Widget _wideContent() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 46,
        child: Text(
          '${index + 1}'.padLeft(2, '0'),
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.heroAccent : AppColors.textSecondary,
            letterSpacing: 0.7,
          ),
        ),
      ),
      Expanded(
        child: Text(
          system.name,
          style: AppFonts.spaceGrotesk(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.heroAccent : AppColors.textBright,
            height: 1.2,
            letterSpacing: -0.35,
          ),
        ),
      ),
      const SizedBox(width: 22),
      SizedBox(
        width: 154,
        child: Text(
          system.kind,
          textAlign: TextAlign.end,
          style: AppFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
      const SizedBox(width: 20),
      Icon(
        Icons.arrow_forward_rounded,
        size: 17,
        color: active ? AppColors.heroAccent : AppColors.textSecondary,
      ),
    ],
  );

  Widget _compactContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.heroAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              system.name,
              style: AppFonts.spaceGrotesk(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                height: 1.16,
                letterSpacing: -0.45,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.north_east_rounded,
            size: 17,
            color: AppColors.heroAccent,
          ),
        ],
      ),
      const SizedBox(height: 13),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${system.kind} · ${system.year}',
              style: AppFonts.jetBrainsMono(
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              system.summary,
              style: AppFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            _TechnologyLine(technologies: system.technologies),
          ],
        ),
      ),
    ],
  );
}

class _ArchivePreview extends StatelessWidget {
  const _ArchivePreview({super.key, required this.system, required this.index});

  final PortfolioSystem system;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.only(start: 42, top: 18, bottom: 26),
    decoration: const BoxDecoration(
      border: BorderDirectional(start: BorderSide(color: Color(0x52E47A57))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1}'.padLeft(2, '0'),
          style: AppFonts.instrumentSerif(
            fontSize: 34,
            fontStyle: FontStyle.italic,
            color: AppColors.heroAccent,
            height: 1,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          system.name,
          style: AppFonts.spaceGrotesk(
            fontSize: 38,
            fontWeight: FontWeight.w600,
            color: AppColors.textBright,
            height: 1,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${system.kind} · ${system.year}',
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            color: AppColors.textSecondary,
            height: 1.5,
            letterSpacing: 0.45,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          system.summary,
          style: AppFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 26),
        _TechnologyLine(technologies: system.technologies),
      ],
    ),
  );
}

class _TechnologyLine extends StatelessWidget {
  const _TechnologyLine({required this.technologies});

  final List<String> technologies;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (var index = 0; index < technologies.length; index++) ...[
        if (index > 0)
          const Text(
            '·',
            style: TextStyle(color: AppColors.heroAccent, fontSize: 11),
          ),
        Text(
          technologies[index],
          style: AppFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}
