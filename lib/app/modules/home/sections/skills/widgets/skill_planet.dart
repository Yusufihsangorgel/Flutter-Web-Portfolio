import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';

/// A draggable skill planet widget displayed within the galaxy view.
class SkillPlanet extends StatelessWidget {

  const SkillPlanet({
    super.key,
    required this.skillName,
    required this.skillColor,
    required this.planetSize,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });
  final String skillName;
  final Color skillColor;
  final double planetSize;
  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onPanStart: (_) => onDragStart(),
      onPanUpdate: onDragUpdate,
      onPanEnd: (_) => onDragEnd(),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: HoverAnimatedWidget(
          hoverScale: 1.2,
          child: Container(
            width: planetSize,
            height: planetSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skillColor,
              boxShadow: [
                BoxShadow(
                  color: skillColor.withValues(alpha:0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Tooltip(
                message: skillName,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSkillIcon(skillName, planetSize * 0.4),
                    const SizedBox(height: 2),
                    Text(
                      _getSkillDisplayName(skillName),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: planetSize * 0.18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

  /// Build a PNG icon widget for the skill.
  Widget _buildSkillIcon(String skillName, double size) {
    final iconPath = _getSkillIconPath(skillName);

    if (iconPath.isEmpty) {
      return _buildFallbackIcon(skillName, size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Show fallback icon when asset is missing

          // Try alternative icons for special cases
          if (iconPath.contains('skills/')) {
            const String basePath = 'assets/icons/';
            final String fileName = iconPath.split('/').last;

            // Try a file with the same name in the general icons directory
            return Image.asset(
              '$basePath$fileName',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // If it fails again, show the fallback icon
                return _buildFallbackIcon(skillName, size);
              },
            );
          }

          return _buildFallbackIcon(skillName, size);
        },
      ),
    );
  }

  /// Get a short display name for the skill, abbreviating if needed.
  String _getSkillDisplayName(String skill) {
    final Map<String, String> shortNames = {
      'JavaScript': 'JS',
      'TypeScript': 'TS',
      'Express.js': 'Express',
      'RESTful API': 'REST API',
    };

    return shortNames[skill] ?? skill;
  }

  /// Get the PNG icon asset path for a skill.
  String _getSkillIconPath(String skill) {
    // Normalize the skill name: lowercase, remove dots/spaces/special chars
    final String normalizedSkill = skill
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(',', '');

    // Special case mappings
    final Map<String, String> specialCases = {
      'nodejs': 'nodejs',
      'expressjs': 'express',
      'javascript': 'javascript',
      'typescript': 'typescript',
      'html': 'html5',
      'css': 'css3',
      'mongodb': 'mongodb',
      'mssql': 'mssql',
      'sqlite': 'sqlite',
      'aws': 'aws',
      'awss3bucket': 'aws', // Use the AWS icon for AWS S3 Bucket
      'react': 'react',
      'flutter': 'flutter',
      'restfulapi': 'api', // Use a generic API icon for RESTful API
      'websocket': 'websocket',
      'statemanagementgetxproviderbloc':
          'flutter', // Use the Flutter icon for state management
    };

    // Check for special cases
    final String iconName = specialCases[normalizedSkill] ?? normalizedSkill;

    // Build the file path
    final String iconPath = 'assets/icons/skills/$iconName.png';

    return iconPath;
  }

  /// Fallback icon when the asset is not available.
  Widget _buildFallbackIcon(String skillName, double size) {
    final Color iconColor = _getSkillColor(skillName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha:0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          skillName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  /// Determine the color for a skill based on its category keywords.
  Color _getSkillColor(String skill) {
    final String normalizedSkill = skill.toLowerCase();

    if (normalizedSkill.contains('flutter') ||
        normalizedSkill.contains('mobile') ||
        normalizedSkill.contains('android') ||
        normalizedSkill.contains('ios')) {
      return Colors.blue[400]!;
    } else if (normalizedSkill.contains('node') ||
        normalizedSkill.contains('express') ||
        normalizedSkill.contains('api') ||
        normalizedSkill.contains('rest')) {
      return Colors.green[500]!;
    } else if (normalizedSkill.contains('react') ||
        normalizedSkill.contains('javascript') ||
        normalizedSkill.contains('html') ||
        normalizedSkill.contains('css')) {
      return Colors.orange[400]!;
    } else if (normalizedSkill.contains('aws') ||
        normalizedSkill.contains('docker') ||
        normalizedSkill.contains('git')) {
      return Colors.purple[400]!;
    } else if (normalizedSkill.contains('sql') ||
        normalizedSkill.contains('mongo') ||
        normalizedSkill.contains('database')) {
      return Colors.teal[400]!;
    }

    // Default color
    return Colors.blue[300]!;
  }
}
