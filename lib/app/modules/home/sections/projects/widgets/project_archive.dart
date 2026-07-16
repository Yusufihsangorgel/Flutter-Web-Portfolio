import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

@immutable
final class ProjectArchiveLabels {
  const ProjectArchiveLabels({
    required this.scope,
    required this.decision,
    required this.openEvidence,
  });

  final String scope;
  final String decision;
  final String openEvidence;
}

/// A release ledger for supporting work.
///
/// The ledger avoids a card catalogue and a duplicate master-detail preview.
/// Every expanded record exposes a real, content-authored artifact alongside
/// first-person ownership, an engineering decision, and public evidence.
final class ProjectArchive extends StatefulWidget {
  const ProjectArchive({
    super.key,
    required this.systems,
    required this.labels,
  });

  final List<PortfolioSupportingSystem> systems;
  final ProjectArchiveLabels labels;

  @override
  State<ProjectArchive> createState() => _ProjectArchiveState();
}

final class _ProjectArchiveState extends State<ProjectArchive> {
  late String _activeId;

  @override
  void initState() {
    super.initState();
    _activeId = widget.systems.firstOrNull?.id ?? '';
  }

  @override
  void didUpdateWidget(ProjectArchive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.systems.any((system) => system.id == _activeId)) {
      _activeId = widget.systems.firstOrNull?.id ?? '';
    }
  }

  void _select(String id) {
    if (id == _activeId || !mounted) return;
    setState(() => _activeId = id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.systems.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedLedger = constraints.maxWidth < 720;
        return DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x42F2F0E9))),
          ),
          child: Column(
            children: [
              for (var index = 0; index < widget.systems.length; index++)
                _LedgerFold(
                  key: ValueKey('project-archive-${widget.systems[index].id}'),
                  system: widget.systems[index],
                  index: index,
                  active:
                      expandedLedger || widget.systems[index].id == _activeId,
                  selectable: !expandedLedger,
                  labels: widget.labels,
                  onSelected: () => _select(widget.systems[index].id),
                ),
            ],
          ),
        );
      },
    );
  }
}

final class _LedgerFold extends StatelessWidget {
  const _LedgerFold({
    super.key,
    required this.system,
    required this.index,
    required this.active,
    required this.selectable,
    required this.labels,
    required this.onSelected,
  });

  final PortfolioSupportingSystem system;
  final int index;
  final bool active;
  final bool selectable;
  final ProjectArchiveLabels labels;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final body = active
        ? _LedgerBody(
            key: ValueKey('project-artifact-${system.id}'),
            system: system,
            labels: labels,
          )
        : const SizedBox.shrink();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x2EF2F0E9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LedgerHeader(
            system: system,
            index: index,
            active: active,
            selectable: selectable,
            onSelected: onSelected,
          ),
          body,
        ],
      ),
    );
  }
}

final class _LedgerHeader extends StatelessWidget {
  const _LedgerHeader({
    required this.system,
    required this.index,
    required this.active,
    required this.selectable,
    required this.onSelected,
  });

  final PortfolioSupportingSystem system;
  final int index;
  final bool active;
  final bool selectable;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Builder(
    builder: (anchorContext) => CinematicFocusable(
      onTap: selectable
          ? () => _selectWithoutMoving(anchorContext)
          : () => launchUrl(system.url, webOnlyWindowName: '_blank'),
      semanticLabel:
          '${system.name}. ${system.kind}. ${system.year}. ${system.summary}',
      semanticRole: selectable
          ? CinematicControlRole.button
          : CinematicControlRole.link,
      selected: selectable ? active : null,
      expanded: selectable ? active : null,
      focusColor: AppColors.heroAccent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final highlighted = selectable && active;
          return Stack(
            children: [
              if (highlighted)
                const PositionedDirectional(
                  start: 0,
                  top: 18,
                  bottom: 18,
                  child: ColoredBox(
                    color: AppColors.heroAccent,
                    child: SizedBox(width: 2),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: compact ? 92 : 78),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    compact ? 0 : 20,
                    compact ? 21 : 17,
                    4,
                    compact ? 20 : 16,
                  ),
                  child: compact
                      ? _CompactHeader(system: system, index: index)
                      : _WideHeader(
                          system: system,
                          index: index,
                          active: highlighted,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _selectWithoutMoving(BuildContext context) {
    if (active) return;
    final scrollable = Scrollable.maybeOf(context);
    final before = context.findRenderObject();
    if (scrollable == null || before is! RenderBox || !before.hasSize) {
      onSelected();
      return;
    }
    final anchorY = before.localToGlobal(Offset.zero).dy;
    onSelected();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || !scrollable.position.hasContentDimensions) {
        return;
      }
      final after = context.findRenderObject();
      if (after is! RenderBox || !after.hasSize) return;
      final delta = after.localToGlobal(Offset.zero).dy - anchorY;
      if (delta.abs() < 0.5) return;
      final position = scrollable.position;
      final target = (position.pixels + delta)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      position.jumpTo(target);
    });
  }
}

final class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.system,
    required this.index,
    required this.active,
  });

  final PortfolioSupportingSystem system;
  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 54,
        child: Text(
          '${index + 1}'.padLeft(2, '0'),
          style: AppFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.heroAccent : AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ),
      Expanded(
        child: Text(
          system.name,
          style: AppFonts.spaceGrotesk(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.heroAccent : AppColors.textBright,
            height: 1.16,
            letterSpacing: -0.5,
          ),
        ),
      ),
      const SizedBox(width: 30),
      SizedBox(
        width: 190,
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
      const SizedBox(width: 30),
      SizedBox(
        width: 96,
        child: Text(
          system.year,
          textAlign: TextAlign.end,
          style: AppFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      const SizedBox(width: 24),
      Icon(
        active ? Icons.circle : Icons.add_rounded,
        size: active ? 7 : 18,
        color: active ? AppColors.heroAccent : AppColors.textSecondary,
      ),
    ],
  );
}

final class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.system, required this.index});

  final PortfolioSupportingSystem system;
  final int index;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '${index + 1}'.padLeft(2, '0'),
              style: AppFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.heroAccent,
              ),
            ),
          ),
          Expanded(
            child: Text(
              system.name,
              style: AppFonts.spaceGrotesk(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
                height: 1.15,
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
      const SizedBox(height: 11),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 44),
        child: Text(
          '${system.kind} · ${system.year}',
          style: AppFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ),
    ],
  );
}

final class _LedgerBody extends StatelessWidget {
  const _LedgerBody({super.key, required this.system, required this.labels});

  final PortfolioSupportingSystem system;
  final ProjectArchiveLabels labels;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1024;
      final compact = constraints.maxWidth < 720;
      final composition = system.artifact.composition;
      final artifact = _ArtifactPane(
        system: system,
        imageHeight: compact
            ? 310
            : wide
            ? composition == PortfolioArtifactComposition.portraitSplit
                  ? 440
                  : 420
            : 360,
      );
      final narrative = _ArchiveNarrative(
        system: system,
        labels: labels,
        editorialSplit:
            wide && composition == PortfolioArtifactComposition.evidenceStack,
      );

      return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          wide ? 74 : 44,
          wide ? 28 : 20,
          wide ? 44 : 0,
          wide ? 66 : 62,
        ),
        child: wide && composition == PortfolioArtifactComposition.portraitSplit
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: artifact),
                  const SizedBox(width: 68),
                  Expanded(flex: 7, child: narrative),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  artifact,
                  SizedBox(height: wide ? 54 : 42),
                  narrative,
                ],
              ),
      );
    },
  );
}

final class _ArtifactPane extends StatelessWidget {
  const _ArtifactPane({required this.system, required this.imageHeight});

  final PortfolioSupportingSystem system;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final artifact = system.artifact;
    final alignment = switch (artifact.alignment) {
      PortfolioArtifactAlignment.start => AlignmentDirectional.centerStart,
      PortfolioArtifactAlignment.center => AlignmentDirectional.center,
      PortfolioArtifactAlignment.end => AlignmentDirectional.centerEnd,
    };
    final fit = switch (artifact.fit) {
      PortfolioArtifactFit.contain => BoxFit.contain,
      PortfolioArtifactFit.cover => BoxFit.cover,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          artifact.label,
          style: AppFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.heroAccent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: ClipRect(
            child: Align(
              alignment: alignment,
              child: artifact.fit == PortfolioArtifactFit.contain
                  ? AspectRatio(
                      aspectRatio: artifact.width / artifact.height,
                      child: Image.asset(
                        artifact.asset,
                        fit: fit,
                        alignment: alignment.resolve(
                          Directionality.of(context),
                        ),
                        semanticLabel: artifact.alt,
                        filterQuality: FilterQuality.medium,
                      ),
                    )
                  : SizedBox.expand(
                      child: Image.asset(
                        artifact.asset,
                        fit: fit,
                        alignment: alignment.resolve(
                          Directionality.of(context),
                        ),
                        semanticLabel: artifact.alt,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          artifact.caption,
          style: AppFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

final class _ArchiveNarrative extends StatelessWidget {
  const _ArchiveNarrative({
    required this.system,
    required this.labels,
    required this.editorialSplit,
  });

  final PortfolioSupportingSystem system;
  final ProjectArchiveLabels labels;
  final bool editorialSplit;

  @override
  Widget build(BuildContext context) {
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          system.summary,
          style: AppFonts.spaceGrotesk(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            color: AppColors.textBright,
            height: 1.46,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          system.technologies.join(' · '),
          style: AppFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.55,
          ),
        ),
      ],
    );
    final notes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ArchiveNote(label: labels.scope, value: system.ownership),
        const SizedBox(height: 28),
        _ArchiveNote(label: labels.decision, value: system.decision),
      ],
    );
    final evidence = _ArchiveEvidenceList(system: system, labels: labels);

    if (editorialSplit) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [summary, const SizedBox(height: 34), evidence],
            ),
          ),
          const SizedBox(width: 72),
          Expanded(flex: 5, child: notes),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        summary,
        const SizedBox(height: 34),
        notes,
        const SizedBox(height: 36),
        evidence,
      ],
    );
  }
}

final class _ArchiveEvidenceList extends StatelessWidget {
  const _ArchiveEvidenceList({required this.system, required this.labels});

  final PortfolioSupportingSystem system;
  final ProjectArchiveLabels labels;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x2EF2F0E9))),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < system.evidence.length; index++)
          _ArchiveEvidenceLink(
            key: ValueKey('archive-evidence-${system.id}-$index'),
            system: system,
            evidence: system.evidence[index],
            openLabel: labels.openEvidence,
          ),
      ],
    ),
  );
}

final class _ArchiveNote extends StatelessWidget {
  const _ArchiveNote({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.heroAccent,
          letterSpacing: 0.9,
        ),
      ),
      const SizedBox(height: 9),
      Text(
        value,
        style: AppFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
          height: 1.65,
        ),
      ),
    ],
  );
}

final class _ArchiveEvidenceLink extends StatelessWidget {
  const _ArchiveEvidenceLink({
    super.key,
    required this.system,
    required this.evidence,
    required this.openLabel,
  });

  final PortfolioSupportingSystem system;
  final PortfolioEvidence evidence;
  final String openLabel;

  @override
  Widget build(BuildContext context) => CinematicFocusable(
    onTap: () => launchUrl(evidence.url, webOnlyWindowName: '_blank'),
    semanticLabel: '$openLabel: ${system.name}, ${evidence.label}',
    semanticRole: CinematicControlRole.link,
    focusColor: AppColors.heroAccent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                evidence.label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBright,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Flexible(
              child: Text(
                evidence.kind,
                textAlign: TextAlign.end,
                style: AppFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.north_east_rounded,
              size: 16,
              color: AppColors.heroAccent,
            ),
          ],
        ),
      ),
    ),
  );
}
