import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';

/// Data for a single skill placed on an orbit ring.
class _SkillNode {
  _SkillNode({
    required this.name,
    required this.category,
    required this.orbitIndex,
    required this.angleOffset,
  });

  final String name;
  final String category;
  final int orbitIndex;
  final double angleOffset;
}

/// Orbit ring configuration.
class _OrbitConfig {
  const _OrbitConfig(this.rxFrac, this.ryFrac, this.speed);

  final double rxFrac;
  final double ryFrac;
  final double speed;
}

/// Computed position of a skill node in a single frame.
class _PositionedNode {
  _PositionedNode(this.index, this.x, this.y, this.z);

  final int index;
  final double x;
  final double y;
  final double z;
}

/// 3D interactive skill orbit visualization.
///
/// Renders concentric elliptical orbits with skill names orbiting as "planets".
/// Skills closer to the viewer appear larger (simulated z-axis via sin/cos).
/// Mouse hover highlights a skill and shows its category in a tooltip.
class SkillOrbit extends StatefulWidget {
  const SkillOrbit({
    super.key,
    required this.skills,
    required this.accent,
  });

  /// Skill data: list of {category, items[]}.
  final List<Map<String, dynamic>> skills;

  /// Scene-aware accent color for orbit lines and highlights.
  final Color accent;

  @override
  State<SkillOrbit> createState() => _SkillOrbitState();
}

class _SkillOrbitState extends State<SkillOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset? _mousePosition;
  int? _hoveredIndex;
  List<_SkillNode> _nodes = [];

  // 3 orbits with different tilt and speed for visual depth.
  static const _orbitConfigs = [
    _OrbitConfig(0.38, 0.22, 1.0), // inner  — Mobile
    _OrbitConfig(0.56, 0.32, 0.7), // middle — Backend
    _OrbitConfig(0.74, 0.42, 0.5), // outer  — Frontend+DevOps
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _buildNodes();
  }

  @override
  void didUpdateWidget(SkillOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skills != widget.skills) {
      _buildNodes();
    }
  }

  void _buildNodes() {
    _nodes = [];
    final skills = widget.skills;
    if (skills.isEmpty) return;

    // Distribute categories across 3 orbits.
    // Orbit 0: first category (Mobile)
    // Orbit 1: second category (Backend)
    // Orbit 2: remaining categories merged (Frontend + DevOps)
    final orbitAssignments = <int, List<Map<String, dynamic>>>{};

    for (var i = 0; i < skills.length; i++) {
      final skill = skills[i];
      final orbitIdx = i < 2 ? i : 2; // collapse 3+ into orbit 2
      orbitAssignments.putIfAbsent(orbitIdx, () => []).add(skill);
    }

    for (final entry in orbitAssignments.entries) {
      final orbitIdx = entry.key;
      final names = <String>[];
      final categories = <String>[];
      for (final skill in entry.value) {
        final category = skill['category'] as String? ?? '';
        final skillItems = (skill['items'] as List?)?.cast<String>() ?? [];
        for (final item in skillItems) {
          names.add(item);
          categories.add(category);
        }
      }

      // Evenly distribute items around the orbit.
      final count = names.length;
      for (var j = 0; j < count; j++) {
        _nodes.add(_SkillNode(
          name: names[j],
          category: categories[j],
          orbitIndex: orbitIdx,
          angleOffset: (2 * pi * j) / count,
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_nodes.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: MouseRegion(
        onHover: (event) {
          setState(() => _mousePosition = event.localPosition);
        },
        onExit: (_) {
          setState(() {
            _mousePosition = null;
            _hoveredIndex = null;
          });
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 400),
            painter: _SkillOrbitPainter(
              nodes: _nodes,
              animationValue: _controller.value,
              accent: widget.accent,
              mousePosition: _mousePosition,
              orbitConfigs: _orbitConfigs,
              onHoveredIndex: (idx) {
                if (idx != _hoveredIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _hoveredIndex = idx);
                  });
                }
              },
            ),
            child: _hoveredIndex != null
                ? _buildTooltip()
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip() {
    if (_hoveredIndex == null ||
        _hoveredIndex! >= _nodes.length ||
        _mousePosition == null) {
      return const SizedBox.shrink();
    }

    final node = _nodes[_hoveredIndex!];

    return Stack(
      children: [
        Positioned(
          left: (_mousePosition!.dx + 12).clamp(0.0, double.infinity),
          top: (_mousePosition!.dy - 36).clamp(0.0, double.infinity),
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                node.category,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: widget.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── CustomPainter ──────────────────────────────────────────────────────────

class _SkillOrbitPainter extends CustomPainter {
  _SkillOrbitPainter({
    required this.nodes,
    required this.animationValue,
    required this.accent,
    required this.mousePosition,
    required this.orbitConfigs,
    required this.onHoveredIndex,
  });

  final List<_SkillNode> nodes;
  final double animationValue;
  final Color accent;
  final Offset? mousePosition;
  final List<_OrbitConfig> orbitConfigs;
  final ValueChanged<int?> onHoveredIndex;

  // Hit-test radius around each skill label.
  static const _hitRadius = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseSize = min(size.width, size.height);

    // Draw orbit ellipses.
    for (final config in orbitConfigs) {
      final rx = baseSize * config.rxFrac;
      final ry = baseSize * config.ryFrac;

      final orbitPaint = Paint()
        ..color = accent.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: rx * 2,
          height: ry * 2,
        ),
        orbitPaint,
      );
    }

    // Compute positions for all nodes, sorted by depth (back-to-front).
    final positioned = <_PositionedNode>[];

    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final config = orbitConfigs[node.orbitIndex.clamp(0, orbitConfigs.length - 1)];
      final rx = baseSize * config.rxFrac;
      final ry = baseSize * config.ryFrac;

      // Current angle = base rotation * speed + offset.
      final angle =
          animationValue * 2 * pi * config.speed + node.angleOffset;

      final x = centerX + rx * cos(angle);
      final y = centerY + ry * sin(angle);
      // Z simulates depth: -1 (far) to 1 (near) based on sin of angle.
      final z = sin(angle);

      positioned.add(_PositionedNode(i, x, y, z));
    }

    // Sort back-to-front so nearer labels paint on top.
    positioned.sort((a, b) => a.z.compareTo(b.z));

    // Track hover.
    int? hoveredIdx;

    for (final item in positioned) {
      final node = nodes[item.index];
      // Depth-based scaling: 0.5 (far) to 1.0 (near).
      final depthScale = 0.5 + (item.z + 1.0) / 2.0 * 0.5;
      // Depth-based opacity: 0.3 (far) to 1.0 (near).
      final depthAlpha = 0.3 + (item.z + 1.0) / 2.0 * 0.7;

      final fontSize = 13.0 * depthScale;
      final isHovered = mousePosition != null &&
          (Offset(item.x, item.y) - mousePosition!).distance < _hitRadius;

      if (isHovered) hoveredIdx = item.index;

      final labelColor = isHovered
          ? accent
          : AppColors.textBright.withValues(alpha: depthAlpha);

      // Draw a subtle dot at the node position.
      final dotPaint = Paint()
        ..color = (isHovered ? accent : accent.withValues(alpha: depthAlpha * 0.5));
      canvas.drawCircle(Offset(item.x, item.y), isHovered ? 3.5 : 2.0, dotPaint);

      // Draw glow ring on hover.
      if (isHovered) {
        final glowPaint = Paint()
          ..color = accent.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(item.x, item.y), 18.0, glowPaint);
      }

      // Draw skill label using TextPainter.
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.name,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
            fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
            letterSpacing: isHovered ? 0.5 : 0.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Position label slightly above the dot.
      textPainter.paint(
        canvas,
        Offset(
          item.x - textPainter.width / 2,
          item.y - textPainter.height - 6 * depthScale,
        ),
      );
    }

    onHoveredIndex(hoveredIdx);
  }

  @override
  bool shouldRepaint(_SkillOrbitPainter old) => true;
}
