import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'galaxy_rings_painter.dart';
import 'skill_planet.dart';

class GalaxyView extends StatefulWidget {
  const GalaxyView({
    super.key,
    required this.galaxySize,
    required this.centralPlanetSize,
    required this.skillCategories,
  });

  final double galaxySize;
  final double centralPlanetSize;
  final List<dynamic> skillCategories;

  @override
  State<GalaxyView> createState() => _GalaxyViewState();
}

class _GalaxyViewState extends State<GalaxyView>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbitController;
  int? _draggedPlanetIndex;
  List<double> _dragAngles = [];
  List<Map<String, dynamic>> _skills = [];

  @override
  void initState() {
    super.initState();
    _skills = _extractMainSkills();
    _dragAngles = List.generate(_skills.length, (i) {
      final skillsInOrbit = (_skills.length / 3).ceil();
      final orbitPos = (i / 3).floor();
      return 2 * math.pi * orbitPos / skillsInOrbit;
    });

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _extractMainSkills() {
    final List<Map<String, dynamic>> mainSkills = [];

    try {
      final Map<String, Color> categoryColors = {
        'Mobile': Colors.blue[400]!,
        'Frontend': Colors.orange[400]!,
        'Backend': Colors.green[500]!,
        'DevOps': Colors.purple[400]!,
        'Database': Colors.teal[400]!,
      };

      if (widget.skillCategories.isEmpty) return _getFallbackSkills();

      for (final skillCategory in widget.skillCategories) {
        final String category = skillCategory['category'] ?? '';
        final List<dynamic> items = skillCategory['items'] ?? [];

        if (category.isEmpty || items.isEmpty) continue;

        const maxItemsPerCategory = 4;
        final itemsToTake = math.min(items.length, maxItemsPerCategory);

        for (int i = 0; i < itemsToTake; i++) {
          final skill = items[i];
          if (skill is String) {
            mainSkills.add({
              'name': skill,
              'category': category,
              'color': categoryColors[category] ?? Colors.grey[400]!,
              'orbit': mainSkills.length % 3,
            });
          }
        }
      }

      if (mainSkills.length > 12) {
        mainSkills.shuffle();
        return mainSkills.sublist(0, 12);
      }

      return mainSkills.isEmpty ? _getFallbackSkills() : mainSkills;
    } catch (_) {
      return _getFallbackSkills();
    }
  }

  List<Map<String, dynamic>> _getFallbackSkills() => [
    {'name': 'Flutter', 'category': 'Mobile', 'color': Colors.blue[400]!, 'orbit': 0},
    {'name': 'React', 'category': 'Frontend', 'color': Colors.orange[400]!, 'orbit': 1},
    {'name': 'Node.js', 'category': 'Backend', 'color': Colors.green[500]!, 'orbit': 2},
    {'name': 'TypeScript', 'category': 'Frontend', 'color': Colors.orange[400]!, 'orbit': 0},
    {'name': 'Python', 'category': 'Backend', 'color': Colors.green[500]!, 'orbit': 1},
    {'name': 'Docker', 'category': 'DevOps', 'color': Colors.purple[400]!, 'orbit': 2},
  ];

  Offset _planetPosition(int index, double animValue) {
    final orbitIndex = _skills[index]['orbit'] as int;
    // Reduced radii to prevent overflow: max orbit at 0.38 * galaxySize
    final orbitRadius = widget.galaxySize * (0.2 + orbitIndex * 0.09);

    // Each orbit rotates at a different speed
    final speed = switch (orbitIndex) {
      0 => 1.0,
      1 => -0.7,
      _ => 0.5,
    };

    final baseAngle = _dragAngles[index];
    final angle = _draggedPlanetIndex == index
        ? baseAngle
        : baseAngle + animValue * 2 * math.pi * speed;

    final center = widget.galaxySize / 2;
    return Offset(
      center + orbitRadius * math.cos(angle),
      center + orbitRadius * math.sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ClipRect(
      child: SizedBox(
        width: widget.galaxySize,
        height: widget.galaxySize,
        child: AnimatedBuilder(
          animation: _orbitController,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: GalaxyRingsPainter(galaxySize: widget.galaxySize),
                ),
              ),
              Center(
                child: HoverAnimatedWidget(
                  hoverScale: 1.05,
                  child: Container(
                    width: widget.centralPlanetSize,
                    height: widget.centralPlanetSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue[400]!,
                          Colors.blue[400]!.withValues(alpha: 0.7),
                          Colors.blue[400]!.withValues(alpha: 0.3),
                        ],
                        stops: const [0.2, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue[400]!.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.code,
                        size: widget.centralPlanetSize * 0.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(_skills.length, (index) {
                final skill = _skills[index];
                final orbitIndex = skill['orbit'] as int;
                final planetSizeFactor = 1.0 - (orbitIndex * 0.1);
                final planetSize = widget.galaxySize * 0.08 * planetSizeFactor;
                final pos = _planetPosition(index, _orbitController.value);

                return Positioned(
                  left: pos.dx - planetSize / 2,
                  top: pos.dy - planetSize / 2,
                  child: SkillPlanet(
                    skillName: skill['name'] as String,
                    skillColor: skill['color'] as Color,
                    planetSize: planetSize,
                    onDragStart: () => setState(() => _draggedPlanetIndex = index),
                    onDragUpdate: (details) {
                      if (_draggedPlanetIndex != index) return;
                      final center = Offset(widget.galaxySize / 2, widget.galaxySize / 2);
                      final newPos = Offset(
                        pos.dx + details.delta.dx,
                        pos.dy + details.delta.dy,
                      );
                      _dragAngles[index] = math.atan2(
                        newPos.dy - center.dy,
                        newPos.dx - center.dx,
                      );
                    },
                    onDragEnd: () => setState(() => _draggedPlanetIndex = null),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ),
  );
}
