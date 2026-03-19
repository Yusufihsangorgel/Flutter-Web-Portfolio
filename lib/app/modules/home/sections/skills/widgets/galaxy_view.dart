import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'galaxy_rings_painter.dart';
import 'skill_planet.dart';

/// Interactive galaxy view that displays skill planets orbiting a central hub.
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

class _GalaxyViewState extends State<GalaxyView> {
  // Track which planet is being dragged
  int? _draggedPlanetIndex;
  List<Offset> _planetPositions = [];
  List<Map<String, dynamic>> _skills = [];

  @override
  void initState() {
    super.initState();
    _skills = _extractMainSkills();
    _initializePlanetPositions();
  }

  void _initializePlanetPositions() {
    // Assign an initial position for each planet
    setState(() {
      _planetPositions = List.generate(_skills.length, (i) {
        // Determine which orbit the planet belongs to
        final orbitIndex = i % 3;
        final orbitRadius = widget.galaxySize * (0.28 + orbitIndex * 0.1);

        // Calculate position within the orbit
        final skillsInThisOrbit = (_skills.length / 3).ceil();
        final orbitPositionIndex = (i / 3).floor();
        final angle = 2 * math.pi * orbitPositionIndex / skillsInThisOrbit;

        // X and Y coordinates
        final x = widget.galaxySize / 2 + orbitRadius * math.cos(angle);
        final y = widget.galaxySize / 2 + orbitRadius * math.sin(angle);

        return Offset(x, y);
      });
    });
  }

  /// Extract main skills from all skill categories - selects only key technologies.
  List<Map<String, dynamic>> _extractMainSkills() {
    final List<Map<String, dynamic>> mainSkills = [];

    try {
      // Category-to-color mapping
      final Map<String, Color> categoryColors = {
        'Mobile': Colors.blue[400]!,
        'Frontend': Colors.orange[400]!,
        'Backend': Colors.green[500]!,
        'DevOps': Colors.purple[400]!,
        'Database': Colors.teal[400]!,
      };

      // Get data from JSON
      if (widget.skillCategories.isEmpty) {
        return _getFallbackSkills();
      }

      for (final skillCategory in widget.skillCategories) {
        final String category = skillCategory['category'] ?? '';
        final List<dynamic> items = skillCategory['items'] ?? [];

        if (category.isEmpty) continue;
        if (items.isEmpty) continue;

        // Take at most 4 skills per category (to avoid overcrowding the galaxy view)
        const int maxItemsPerCategory = 4;
        final int itemsToTake = math.min(items.length, maxItemsPerCategory);

        for (int i = 0; i < itemsToTake; i++) {
          final skill = items[i];
          if (skill is String) {
            mainSkills.add({
              'name': skill,
              'category': category,
              'color': categoryColors[category] ?? Colors.grey[400]!,
              'orbit': mainSkills.length % 3, // 3 different orbits (0, 1, 2)
            });
          }
        }
      }

      // Show at most 12 skills
      if (mainSkills.length > 12) {
        mainSkills.shuffle(); // Random selection
        return mainSkills.sublist(0, 12);
      }

      // If no skills were found, show fallback skills
      if (mainSkills.isEmpty) {
        return _getFallbackSkills();
      }

      return mainSkills;
    } catch (_) {
      return _getFallbackSkills();
    }
  }

  /// Fallback skills used when JSON data cannot be loaded.
  List<Map<String, dynamic>> _getFallbackSkills() => [
      {
        'name': 'Flutter',
        'category': 'Mobile',
        'color': Colors.blue[400]!,
        'orbit': 0,
      },
      {
        'name': 'React',
        'category': 'Frontend',
        'color': Colors.orange[400]!,
        'orbit': 1,
      },
      {
        'name': 'Node.js',
        'category': 'Backend',
        'color': Colors.green[500]!,
        'orbit': 2,
      },
      {
        'name': 'JavaScript',
        'category': 'Frontend',
        'color': Colors.orange[400]!,
        'orbit': 0,
      },
      {
        'name': 'HTML',
        'category': 'Frontend',
        'color': Colors.orange[400]!,
        'orbit': 1,
      },
      {
        'name': 'CSS',
        'category': 'Frontend',
        'color': Colors.orange[400]!,
        'orbit': 2,
      },
    ];

  @override
  Widget build(BuildContext context) => Center(
      child: SizedBox(
        width: widget.galaxySize,
        height: widget.galaxySize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background galaxy rings
            Positioned.fill(
              child: CustomPaint(
                painter: GalaxyRingsPainter(galaxySize: widget.galaxySize),
              ),
            ),

            // Central planet (main blue planet)
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
                        Colors.blue[400]!.withValues(alpha:0.7),
                        Colors.blue[400]!.withValues(alpha:0.3),
                      ],
                      stops: const [0.2, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[400]!.withValues(alpha:0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.code,
                      size: widget.centralPlanetSize * 0.5,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                ),
              ),
            ),

            // Orbiting planets (skills)
            ...List.generate(
              _skills.length,
              _buildDraggablePlanet,
            ),
          ],
        ),
      ),
    );

  Widget _buildDraggablePlanet(int index) {
    if (index >= _skills.length || index >= _planetPositions.length) {
      return const SizedBox.shrink();
    }

    final skill = _skills[index];
    final String skillName = skill['name'] as String;
    final Color skillColor = skill['color'] as Color;
    final int orbitIndex = skill['orbit'] as int;

    // Planet size - different sizes for different orbits
    final double planetSizeFactor = 1.0 - (orbitIndex * 0.1);
    final double planetSize = widget.galaxySize * 0.08 * planetSizeFactor;

    // Current position of the planet
    final position = _planetPositions[index];

    return Positioned(
      left: position.dx - planetSize / 2,
      top: position.dy - planetSize / 2,
      child: SkillPlanet(
        skillName: skillName,
        skillColor: skillColor,
        planetSize: planetSize,
        onDragStart: () {
          setState(() {
            _draggedPlanetIndex = index;
          });
        },
        onDragUpdate: (details) {
          if (_draggedPlanetIndex == index) {
            setState(() {
              // Calculate center point
              final center = Offset(
                widget.galaxySize / 2,
                widget.galaxySize / 2,
              );
              final newPos = Offset(
                position.dx + details.delta.dx,
                position.dy + details.delta.dy,
              );

              // Calculate angle from center to new position
              final angle = math.atan2(
                newPos.dy - center.dy,
                newPos.dx - center.dx,
              );

              // Orbit radius - keep it fixed
              final orbitRadius =
                  widget.galaxySize * (0.28 + orbitIndex * 0.1);

              // Calculate new position, constrained to the same orbit
              _planetPositions[index] = Offset(
                center.dx + orbitRadius * math.cos(angle),
                center.dy + orbitRadius * math.sin(angle),
              );
            });
          }
        },
        onDragEnd: () {
          setState(() {
            _draggedPlanetIndex = null;
          });
        },
      ),
    );
  }
}
