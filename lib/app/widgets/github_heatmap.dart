import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';

/// A GitHub contribution heatmap that fetches event data from the public API
/// and renders a 13-week (90-day) grid coloured by contribution intensity.
///
/// Falls back gracefully to an empty grid if the API is unreachable.
/// Data is cached in memory per-username to avoid redundant requests.
class GitHubHeatmap extends StatefulWidget {
  const GitHubHeatmap({super.key});

  @override
  State<GitHubHeatmap> createState() => _GitHubHeatmapState();
}

class _GitHubHeatmapState extends State<GitHubHeatmap> {
  /// In-memory cache keyed by username.
  static final Map<String, Map<String, int>> _cache = {};

  Map<String, int> _contributions = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchContributions();
  }

  String _resolveUsername() {
    final lang = Get.find<LanguageController>();
    final github =
        (lang.cvData['personal_info']?['github'] as String?) ?? '';
    final uri = Uri.tryParse(github);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return '';
  }

  Future<void> _fetchContributions() async {
    final username = _resolveUsername();
    if (username.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Return cached data if available.
    if (_cache.containsKey(username)) {
      if (mounted) {
        setState(() {
          _contributions = _cache[username]!;
          _loading = false;
        });
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/users/$username/events?per_page=100',
            ),
            headers: const {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final events = json.decode(response.body) as List;
        final counts = <String, int>{};
        final cutoff = DateTime.now().subtract(const Duration(days: 90));

        for (final event in events) {
          final createdAt =
              (event as Map<String, dynamic>)['created_at'] as String?;
          if (createdAt == null) continue;
          final date = DateTime.tryParse(createdAt);
          if (date == null || date.isBefore(cutoff)) continue;
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          counts[key] = (counts[key] ?? 0) + 1;
        }

        _cache[username] = counts;

        if (mounted) {
          setState(() {
            _contributions = counts;
            _loading = false;
          });
        }
      } else {
        dev.log(
          'GitHub Events API returned ${response.statusCode}',
          name: 'GitHubHeatmap',
        );
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      dev.log('Failed to fetch GitHub events', name: 'GitHubHeatmap', error: e);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return ExcludeSemantics(
      child: Obx(() {
        final accent = Get.find<SceneDirector>().currentAccent.value;
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CustomPaint(
            painter: _HeatmapPainter(
              contributions: _contributions,
              accent: accent,
            ),
            size: const Size(13 * 12, 7 * 12),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.contributions,
    required this.accent,
  });

  final Map<String, int> contributions;
  final Color accent;

  static const double _cellSize = 10;
  static const double _gap = 2;
  static const double _step = _cellSize + _gap;
  static const double _radius = 2;
  static const int _weeks = 13;
  static const int _days = 7;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final now = DateTime.now();
    // Start from 90 days ago, aligned to the beginning of that week (Monday).
    final origin = now.subtract(const Duration(days: 90));
    final startOfWeek =
        origin.subtract(Duration(days: origin.weekday - 1));

    final emptyPaint = Paint()..color = accent.withValues(alpha: 0.1);

    for (var week = 0; week < _weeks; week++) {
      for (var day = 0; day < _days; day++) {
        final cellDate = startOfWeek.add(Duration(days: week * 7 + day));
        // Skip future dates.
        if (cellDate.isAfter(now)) continue;

        final key =
            '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
        final count = contributions[key] ?? 0;

        final paint = Paint()..color = _colorForCount(count);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            week * _step,
            day * _step,
            _cellSize,
            _cellSize,
          ),
          const Radius.circular(_radius),
        );

        canvas.drawRRect(rect, count > 0 ? paint : emptyPaint);
      }
    }
  }

  Color _colorForCount(int count) {
    if (count == 0) return accent.withValues(alpha: 0.1);
    if (count <= 2) return accent.withValues(alpha: 0.3);
    if (count <= 5) return accent.withValues(alpha: 0.5);
    return accent.withValues(alpha: 0.8);
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      accent != old.accent || contributions != old.contributions;
}
