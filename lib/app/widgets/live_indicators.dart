import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LocalTimeDisplay — Real-time clock with availability indicator
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the current local time with a blinking colon animation and an
/// availability status based on working hours (09:00–22:00).
class LocalTimeDisplay extends StatefulWidget {
  const LocalTimeDisplay({
    super.key,
    this.workStartHour = 9,
    this.workEndHour = 22,
  });

  /// Hour (0–23) when availability begins.
  final int workStartHour;

  /// Hour (0–23) when availability ends.
  final int workEndHour;

  @override
  State<LocalTimeDisplay> createState() => _LocalTimeDisplayState();
}

class _LocalTimeDisplayState extends State<LocalTimeDisplay>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _blinkController;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  bool get _isAvailable =>
      _now.hour >= widget.workStartHour && _now.hour < widget.workEndHour;

  String get _timezone {
    final offset = _now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    return 'UTC$sign$hours';
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final available = _isAvailable;
    final dotColor = available ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Availability dot with pulse
        _PulseDot(color: dotColor),
        const SizedBox(width: 8),
        // Time display
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              h,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
            // Blinking colon
            AnimatedBuilder(
              animation: _blinkController,
              builder: (_, __) => Opacity(
                opacity: 0.3 + 0.7 * _blinkController.value,
                child: Text(
                  ':',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                ),
              ),
            ),
            Text(
              m,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
            AnimatedBuilder(
              animation: _blinkController,
              builder: (_, __) => Opacity(
                opacity: 0.3 + 0.7 * _blinkController.value,
                child: Text(
                  ':',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                ),
              ),
            ),
            Text(
              s,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBright,
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          _timezone,
          style: AppTypography.caption.copyWith(fontSize: 10),
        ),
        const SizedBox(width: 10),
        Text(
          available ? 'Available for work' : 'Currently sleeping',
          style: AppTypography.caption.copyWith(
            color: dotColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LiveVisitorCount — Simulated visitor counter
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a simulated visitor count that varies by time of day with smooth
/// animated transitions and a subtle pulse effect.
class LiveVisitorCount extends StatefulWidget {
  const LiveVisitorCount({super.key});

  @override
  State<LiveVisitorCount> createState() => _LiveVisitorCountState();
}

class _LiveVisitorCountState extends State<LiveVisitorCount>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  final _random = Random();
  int _count = 0;
  int _displayCount = 0;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _count = _computeBaseCount();
    _displayCount = _count;

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final newCount = _computeBaseCount();
      _animateCountTo(newCount);
    });
  }

  /// Produces a plausible visitor count based on time of day.
  int _computeBaseCount() {
    final hour = DateTime.now().hour;
    // Bell curve peaking at business hours (10–16) in local time.
    int base;
    if (hour >= 9 && hour <= 17) {
      base = 5 + _random.nextInt(4); // 5–8
    } else if (hour >= 18 && hour <= 22) {
      base = 3 + _random.nextInt(3); // 3–5
    } else {
      base = 1 + _random.nextInt(2); // 1–2
    }
    // Small jitter
    return base + _random.nextInt(3);
  }

  void _animateCountTo(int target) {
    _transitionTimer?.cancel();
    final diff = target - _displayCount;
    if (diff == 0) return;
    final steps = diff.abs();
    final direction = diff > 0 ? 1 : -1;
    var step = 0;

    _transitionTimer = Timer.periodic(
      const Duration(milliseconds: 80),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        step++;
        setState(() => _displayCount += direction);
        if (step >= steps) {
          t.cancel();
          _count = target;
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _transitionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.visibility_outlined,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + 0.04 * _pulseController.value,
            child: child,
          ),
          child: Text(
            '$_displayCount',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.heroAccent,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'viewing this portfolio right now',
            style: AppTypography.caption.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpotifyNowPlaying — Music status widget (mock/configurable)
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a currently-playing or last-listened-to track with animated equalizer
/// bars and a vinyl record rotation animation.
///
/// Accepts static data by default. If you later integrate the Spotify Web API,
/// replace [trackName], [artistName], and [albumArtUrl] with live data and set
/// [isPlaying] to `true`.
class SpotifyNowPlaying extends StatefulWidget {
  const SpotifyNowPlaying({
    super.key,
    this.trackName = 'Starboy',
    this.artistName = 'The Weeknd',
    this.albumArtUrl,
    this.isPlaying = false,
  });

  final String trackName;
  final String artistName;
  final String? albumArtUrl;

  /// When `true`, shows "Now playing" with animated equalizer bars and vinyl
  /// rotation. When `false`, shows "Last listened to".
  final bool isPlaying;

  @override
  State<SpotifyNowPlaying> createState() => _SpotifyNowPlayingState();
}

class _SpotifyNowPlayingState extends State<SpotifyNowPlaying>
    with TickerProviderStateMixin {
  late AnimationController _vinylController;
  late AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.isPlaying) {
      _vinylController.repeat();
      _eqController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SpotifyNowPlaying old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !old.isPlaying) {
      _vinylController.repeat();
      _eqController.repeat(reverse: true);
    } else if (!widget.isPlaying && old.isPlaying) {
      _vinylController.stop();
      _eqController.stop();
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _eqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vinyl record
          _VinylRecord(
            controller: _vinylController,
            albumArtUrl: widget.albumArtUrl,
          ),
          const SizedBox(width: 10),
          // Track info
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isPlaying) ...[
                      _EqualizerBars(controller: _eqController),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.isPlaying ? 'Now playing' : 'Last listened to',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF1DB954),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.trackName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBright,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.artistName,
                  style: AppTypography.caption.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spinning vinyl record with optional album art center.
class _VinylRecord extends StatelessWidget {
  const _VinylRecord({required this.controller, this.albumArtUrl});

  final AnimationController controller;
  final String? albumArtUrl;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) => Transform.rotate(
        angle: controller.value * 2 * pi,
        child: child,
      ),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1A2E),
          border: Border.all(color: AppColors.textSecondary, width: 0.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grooves
            for (final r in [12.0, 10.0, 8.0])
              Container(
                width: r * 2,
                height: r * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
              ),
            // Center hole / album art
            if (albumArtUrl != null)
              ClipOval(
                child: Image.network(
                  albumArtUrl!,
                  width: 10,
                  height: 10,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _centerHole(),
                ),
              )
            else
              _centerHole(),
          ],
        ),
      ),
    );
  }

  Widget _centerHole() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.backgroundLight,
        ),
      );
}

/// Three animated equalizer bars.
class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            // Offset each bar's phase so they look independent.
            final phase = (controller.value + i * 0.33) % 1.0;
            final height = 4.0 + 6.0 * sin(phase * pi);
            return Container(
              width: 2,
              height: height,
              margin: EdgeInsets.only(right: i < 2 ? 1.5 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GitHubLatestEvent — Live GitHub activity (latest push/commit)
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches the latest public push event from the GitHub Events API and
/// displays the repo name, commit message, and relative time. Auto-refreshes
/// every 5 minutes.
class GitHubLatestEvent extends StatefulWidget {
  const GitHubLatestEvent({
    super.key,
    required this.username,
    this.refreshInterval = const Duration(minutes: 5),
  });

  final String username;
  final Duration refreshInterval;

  @override
  State<GitHubLatestEvent> createState() => _GitHubLatestEventState();
}

class _GitHubLatestEventState extends State<GitHubLatestEvent>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _typingController;

  bool _loading = true;
  String _repoName = '';
  String _commitMessage = '';
  DateTime? _eventTime;
  bool _isCodingNow = false;

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fetchLatestEvent();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted) _fetchLatestEvent();
    });
  }

  Future<void> _fetchLatestEvent() async {
    if (widget.username.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/users/${widget.username}/events?per_page=10'),
        headers: const {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final events = json.decode(response.body) as List;
        // Find the first PushEvent
        for (final event in events) {
          final e = event as Map<String, dynamic>;
          if (e['type'] == 'PushEvent') {
            final payload = e['payload'] as Map<String, dynamic>;
            final commits = payload['commits'] as List?;
            final repo = e['repo'] as Map<String, dynamic>;
            final repoFullName = repo['name'] as String? ?? '';
            final repoShort = repoFullName.contains('/')
                ? repoFullName.split('/').last
                : repoFullName;
            final createdAt = DateTime.tryParse(e['created_at'] as String? ?? '');

            if (mounted) {
              setState(() {
                _repoName = repoShort;
                _commitMessage =
                    (commits != null && commits.isNotEmpty)
                        ? (commits.last as Map<String, dynamic>)['message']
                                as String? ??
                            ''
                        : 'Updated repository';
                _eventTime = createdAt;
                _loading = false;
                // Consider "coding now" if event was within the last 30 minutes
                _isCodingNow = createdAt != null &&
                    DateTime.now().difference(createdAt).inMinutes < 30;
              });

              if (_isCodingNow) {
                _typingController.repeat(reverse: true);
              } else {
                _typingController.stop();
              }
            }
            return;
          }
        }
      }
      // No push event found
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _typingController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    final d = diff.inDays;
    if (d < 30) return '$d day${d == 1 ? '' : 's'} ago';
    return '${d ~/ 30} month${d ~/ 30 == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading activity...',
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
        ],
      );
    }

    if (_repoName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.commit_rounded,
          size: 14,
          color: AppColors.heroAccent,
        ),
        const SizedBox(width: 6),
        if (_isCodingNow) ...[
          _TypingIndicator(controller: _typingController),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTypography.caption.copyWith(fontSize: 11),
              children: [
                TextSpan(
                  text: _repoName,
                  style: const TextStyle(
                    color: AppColors.heroAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '  '),
                TextSpan(text: _commitMessage),
                const TextSpan(text: '  '),
                if (_eventTime != null)
                  TextSpan(
                    text: _relativeTime(_eventTime!),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Three animated dots that simulate a "typing" indicator.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (controller.value + i * 0.25) % 1.0;
          final opacity = 0.3 + 0.7 * sin(phase * pi);
          return Container(
            width: 3,
            height: 3,
            margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.heroAccent.withValues(alpha: opacity),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WeatherWidget — Current weather (subtle)
// ─────────────────────────────────────────────────────────────────────────────

/// Displays current weather for a configured city using the free wttr.in API.
/// Shows temperature, a condition icon, and a subtle animated weather effect.
class WeatherWidget extends StatefulWidget {
  const WeatherWidget({
    super.key,
    this.city = 'Istanbul',
    this.refreshInterval = const Duration(minutes: 30),
  });

  /// City name for weather lookup. Uses wttr.in format.
  final String city;

  /// How often to re-fetch weather data.
  final Duration refreshInterval;

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _iconAnimController;

  bool _loading = true;
  int _temperature = 0;
  String _condition = '';
  _WeatherType _weatherType = _WeatherType.clear;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fetchWeather();
    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      if (mounted) _fetchWeather();
    });
  }

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/${widget.city}?format=j1'),
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = (data['current_condition'] as List?)?.firstOrNull
            as Map<String, dynamic>?;
        if (current != null && mounted) {
          final tempC = int.tryParse(current['temp_C'] as String? ?? '') ?? 0;
          final code =
              int.tryParse(current['weatherCode'] as String? ?? '') ?? 113;
          final desc = ((current['weatherDesc'] as List?)?.firstOrNull
                  as Map<String, dynamic>?)?['value'] as String? ??
              '';

          setState(() {
            _temperature = tempC;
            _condition = desc;
            _weatherType = _classifyWeather(code);
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  _WeatherType _classifyWeather(int code) {
    // wttr.in weather codes
    if (code == 113) return _WeatherType.clear;
    if (code == 116 || code == 119) return _WeatherType.cloudy;
    if (code == 122) return _WeatherType.overcast;
    if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 311, 314, 317, 353, 356,
         359, 362, 365]
        .contains(code)) {
      return _WeatherType.rain;
    }
    if ([200, 386, 389, 392, 395].contains(code)) return _WeatherType.thunder;
    if ([179, 182, 185, 227, 230, 320, 323, 326, 329, 332, 335, 338, 368, 371,
         374, 377]
        .contains(code)) {
      return _WeatherType.snow;
    }
    return _WeatherType.cloudy;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _iconAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _condition.isEmpty) {
      return const SizedBox(width: 20, height: 20);
    }

    return Tooltip(
      message: _condition,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedWeatherIcon(
            type: _weatherType,
            controller: _iconAnimController,
          ),
          const SizedBox(width: 4),
          Text(
            '$_temperature°C',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _WeatherType { clear, cloudy, overcast, rain, thunder, snow }

/// Renders a small animated weather icon based on [type].
class _AnimatedWeatherIcon extends StatelessWidget {
  const _AnimatedWeatherIcon({
    required this.type,
    required this.controller,
  });

  final _WeatherType type;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomPaint(
          painter: _WeatherIconPainter(
            type: type,
            animValue: controller.value,
          ),
        ),
      ),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  _WeatherIconPainter({required this.type, required this.animValue});

  final _WeatherType type;
  final double animValue;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (type) {
      case _WeatherType.clear:
        _paintSun(canvas, cx, cy, size);
      case _WeatherType.cloudy:
        _paintCloud(canvas, cx, cy, size);
      case _WeatherType.overcast:
        _paintCloud(canvas, cx, cy, size, double_: true);
      case _WeatherType.rain:
        _paintCloud(canvas, cx, cy - 2, size);
        _paintRain(canvas, cx, cy + 4, size);
      case _WeatherType.thunder:
        _paintCloud(canvas, cx, cy - 2, size);
        _paintBolt(canvas, cx, cy + 2, size);
      case _WeatherType.snow:
        _paintCloud(canvas, cx, cy - 2, size);
        _paintSnow(canvas, cx, cy + 4, size);
    }
  }

  void _paintSun(Canvas canvas, double cx, double cy, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 4, paint);

    // Sun rays — animate rotation
    paint // ignore: cascade_invocations
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.7);
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi + animValue * pi * 0.3;
      const inner = 5.5;
      final outer = 7.5 + animValue * 0.8;
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, cy + sin(angle) * inner),
        Offset(cx + cos(angle) * outer, cy + sin(angle) * outer),
        paint,
      );
    }
  }

  void _paintCloud(Canvas canvas, double cx, double cy, Size size,
      {bool double_ = false}) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    // Simple cloud shape — two overlapping circles and a rect
    canvas
      ..drawCircle(Offset(cx - 2, cy), 3.5, paint)
      ..drawCircle(Offset(cx + 2, cy - 1), 3, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 4, cy, 8, 3),
          const Radius.circular(1.5),
        ),
        paint,
      );
    if (double_) {
      paint.color = const Color(0xFF64748B);
      canvas.drawCircle(Offset(cx + 1, cy + 2), 2.5, paint);
    }
  }

  void _paintRain(Canvas canvas, double cx, double cy, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.6 + 0.4 * animValue)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = -1; i <= 1; i++) {
      final x = cx + i * 3.0;
      final yOff = animValue * 3;
      canvas.drawLine(
        Offset(x, cy + yOff),
        Offset(x - 0.5, cy + yOff + 2),
        paint,
      );
    }
  }

  void _paintBolt(Canvas canvas, double cx, double cy, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.5 + 0.5 * animValue)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - 1.5, cy + 3)
      ..lineTo(cx + 1, cy + 2.5)
      ..lineTo(cx - 0.5, cy + 5);
    canvas.drawPath(path, paint);
  }

  void _paintSnow(Canvas canvas, double cx, double cy, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5 + 0.5 * animValue)
      ..style = PaintingStyle.fill;
    for (var i = -1; i <= 1; i++) {
      final x = cx + i * 3.0;
      final yOff = animValue * 2;
      canvas.drawCircle(Offset(x, cy + yOff), 1, paint);
    }
  }

  @override
  bool shouldRepaint(_WeatherIconPainter old) =>
      animValue != old.animValue || type != old.type;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Pulsing dot indicator with a soft glow ring.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final scale = 1.0 + 0.5 * _controller.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.15 * (1 - _controller.value)),
                  ),
                ),
              ),
              // Inner dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
