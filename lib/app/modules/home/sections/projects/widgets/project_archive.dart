import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/widgets/cinematic_focusable.dart';
import 'package:url_launcher/url_launcher.dart';

/// A compact typographic index for supporting work.
final class ProjectArchive extends StatelessWidget {
  const ProjectArchive({super.key, required this.systems});

  final List<PortfolioSystem> systems;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0x33F2F0E9))),
    ),
    child: Column(
      children: [
        for (final system in systems)
          _ArchiveRow(
            key: ValueKey('project-archive-${system.id}'),
            system: system,
          ),
      ],
    ),
  );
}

final class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({super.key, required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    return CinematicFocusable(
      onTap: () => launchUrl(system.url, webOnlyWindowName: '_blank'),
      semanticLabel: '${system.name}. ${system.kind}. ${system.summary}',
      semanticRole: CinematicControlRole.link,
      focusColor: AppColors.heroAccent,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: desktop ? 76 : 96),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x24F2F0E9))),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: desktop ? 22 : 24),
            child: desktop
                ? Row(
                    children: [
                      SizedBox(width: 118, child: _ArchiveYear(system: system)),
                      SizedBox(width: 268, child: _ArchiveName(system: system)),
                      SizedBox(width: 204, child: _ArchiveKind(system: system)),
                      const SizedBox(width: 30),
                      Expanded(child: _ArchiveSummary(system: system)),
                      const SizedBox(width: 22),
                      const _ArchiveArrow(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ArchiveName(system: system)),
                          const SizedBox(width: 18),
                          _ArchiveYear(system: system),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ArchiveKind(system: system),
                      const SizedBox(height: 13),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _ArchiveSummary(system: system)),
                          const SizedBox(width: 18),
                          const _ArchiveArrow(),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

final class _ArchiveName extends StatelessWidget {
  const _ArchiveName({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.name,
    style: AppFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textBright,
      letterSpacing: -0.25,
    ),
  );
}

final class _ArchiveYear extends StatelessWidget {
  const _ArchiveYear({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.year,
    style: AppFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
}

final class _ArchiveKind extends StatelessWidget {
  const _ArchiveKind({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.kind,
    style: AppFonts.spaceGrotesk(fontSize: 13, color: AppColors.textPrimary),
  );
}

final class _ArchiveSummary extends StatelessWidget {
  const _ArchiveSummary({required this.system});

  final PortfolioSystem system;

  @override
  Widget build(BuildContext context) => Text(
    system.summary,
    maxLines: MediaQuery.sizeOf(context).width >= Breakpoints.desktop ? 2 : 4,
    overflow: TextOverflow.ellipsis,
    style: AppFonts.inter(
      fontSize: 13,
      color: AppColors.textPrimary,
      height: 1.55,
    ),
  );
}

final class _ArchiveArrow extends StatelessWidget {
  const _ArchiveArrow();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.north_east_rounded,
    size: 17,
    color: AppColors.heroAccent,
  );
}
