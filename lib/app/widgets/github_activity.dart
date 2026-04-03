import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/breakpoints.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_counter.dart';
import 'package:flutter_web_portfolio/app/widgets/border_light_card.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/skeleton_shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays live GitHub stats and recent repos fetched from the public API.
/// Falls back to static data if the API is unreachable.
class GitHubActivity extends StatefulWidget {
  const GitHubActivity({super.key});

  @override
  State<GitHubActivity> createState() => _GitHubActivityState();
}

class _GitHubActivityState extends State<GitHubActivity> {
  final _provider = Get.find<GitHubProvider>();
  bool _loading = true;
  bool _error = false;

  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _repos = [];
  int _totalStars = 0;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _resolveUsername() {
    final lang = Get.find<LanguageController>();
    final github = (lang.cvData['personal_info']?['github'] as String?) ?? '';
    // Extract username from URL like "https://github.com/username"
    final uri = Uri.tryParse(github);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return '';
  }

  Future<void> _fetchData() async {
    _username = _resolveUsername();
    if (_username.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        _provider.fetchProfile(_username),
        _provider.fetchRecentRepos(_username),
        _provider.fetchTotalStars(_username),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _repos = results[1] as List<Map<String, dynamic>>;
        _totalStars = results[2] as int;
        _loading = false;
        _error = false;
      });
    } catch (e) {
      dev.log('Failed to fetch GitHub data', name: 'GitHubActivity', error: e);
      if (!mounted) return;
      setState(() {
        _profile = GitHubProvider.fallbackProfile(_username);
        _repos = GitHubProvider.fallbackRepos(_username);
        _totalStars = GitHubProvider.fallbackTotalStars;
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingSkeleton();

    return ScrollFadeIn(
      delay: AppDurations.staggerMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          // Section label
          Obx(() {
            final accent = Get.find<SceneDirector>().currentAccent.value;
            final languageController = Get.find<LanguageController>();
            return Row(
              children: [
                Icon(Icons.code_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  languageController.getText('about_section.github_title', defaultValue: 'GitHub Activity'),
                  style: AppTypography.h2.copyWith(color: accent),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          // Stats row
          _StatsRow(
            profile: _profile,
            totalStars: _totalStars,
            isError: _error,
          ),
          const SizedBox(height: 24),
          // Recent repos
          _RecentRepos(repos: _repos),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row: avatar + 3 stat cards
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.profile,
    required this.totalStars,
    required this.isError,
  });

  final Map<String, dynamic> profile;
  final int totalStars;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < Breakpoints.mobile;
    final avatarUrl = profile['avatar_url'] as String? ?? '';
    final repos = profile['public_repos'] as int? ?? 0;
    final followers = profile['followers'] as int? ?? 0;

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      final languageController = Get.find<LanguageController>();
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Avatar
          if (avatarUrl.isNotEmpty)
            Container(
              width: isMobile ? 48 : 56,
              height: isMobile ? 48 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.backgroundLight,
                    child: Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                ),
              ),
            ),
          _StatChip(label: languageController.getText('about_section.github_repos', defaultValue: 'Repos'), value: repos, accent: accent),
          _StatChip(label: languageController.getText('about_section.github_followers', defaultValue: 'Followers'), value: followers, accent: accent),
          _StatChip(label: languageController.getText('about_section.github_stars', defaultValue: 'Stars'), value: totalStars, accent: accent),
          if (isError)
            Text(
              languageController.getText('about_section.github_cached', defaultValue: '(cached)'),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
        ],
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) => ScrollFadeIn(
    delay: AppDurations.staggerShort,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCounter(
            endValue: value,
            duration: const Duration(milliseconds: 1200),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Recent repos grid
// ---------------------------------------------------------------------------
class _RecentRepos extends StatelessWidget {
  const _RecentRepos({required this.repos});

  final List<Map<String, dynamic>> repos;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth >= Breakpoints.tablet ? 3 : (screenWidth >= Breakpoints.mobile ? 2 : 1);

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemCount: repos.length,
        itemBuilder: (context, index) => _RepoCard(
          repo: repos[index],
          accent: accent,
        ),
      );
    });
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({required this.repo, required this.accent});

  final Map<String, dynamic> repo;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final name = repo['name'] as String? ?? '';
    final description = repo['description'] as String? ?? '';
    final language = repo['language'] as String? ?? '';
    final stars = repo['stargazers_count'] as int? ?? 0;
    final htmlUrl = repo['html_url'] as String? ?? '';

    return GestureDetector(
      onTap: htmlUrl.isNotEmpty
          ? () => launchUrl(Uri.parse(htmlUrl), mode: LaunchMode.externalApplication)
          : null,
      child: MouseRegion(
        cursor: htmlUrl.isNotEmpty ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: BorderLightCard(
      glowColor: accent,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (language.isNotEmpty) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _languageColor(language),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  language,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                const Spacer(),
              ],
              const Icon(Icons.star_border_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 2),
              Text(
                '$stars',
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ),
    ),
    );
  }

  Color _languageColor(String lang) => switch (lang.toLowerCase()) {
    'dart' => const Color(0xFF00B4AB),
    'javascript' => const Color(0xFFF7DF1E),
    'typescript' => const Color(0xFF3178C6),
    'swift' => const Color(0xFFFA7343),
    'kotlin' => const Color(0xFF7F52FF),
    'python' => const Color(0xFF3776AB),
    'go' => const Color(0xFF00ADD8),
    'html' => const Color(0xFFE34F26),
    'css' => const Color(0xFF1572B6),
    _ => AppColors.textSecondary,
  };
}

// ---------------------------------------------------------------------------
// Loading skeleton — animated shimmer placeholders
// ---------------------------------------------------------------------------
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 48),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title placeholder
        const SkeletonShimmer(width: 180, height: 24),
        const SizedBox(height: 24),
        // 4 stat chip placeholders
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            4,
            (_) => const SkeletonShimmer(width: 110, height: 40),
          ),
        ),
        const SizedBox(height: 24),
        // 5 repo card placeholders
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: List.generate(
            5,
            (_) => const SkeletonShimmer(width: 220, height: 110),
          ),
        ),
      ],
    ),
  );
}
