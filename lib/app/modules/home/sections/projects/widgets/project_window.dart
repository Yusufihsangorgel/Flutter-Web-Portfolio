import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';

import '../models/project_window_model.dart';

/// A draggable window that displays project details inside the desktop
/// environment.
class ProjectWindow extends StatelessWidget {

  const ProjectWindow({
    super.key,
    required this.project,
    required this.onWindowPositionChanged,
    required this.onClose,
    required this.onMinimize,
    required this.onTap,
    required this.onOpenLink,
    required this.zIndex,
    required this.languageController,
  });
  final ProjectWindowModel project;
  final Function(Offset) onWindowPositionChanged;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onTap;
  final VoidCallback onOpenLink;
  final int zIndex;
  final LanguageController languageController;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: project.windowSize.width,
            height: project.windowSize.height,
            decoration: BoxDecoration(
              color: const Color(0xFF282C34),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Window title bar
                GestureDetector(
                  onPanUpdate: (details) {
                    final newPosition = Offset(
                      project.windowPosition.dx + details.delta.dx,
                      project.windowPosition.dy + details.delta.dy,
                    );

                    // Keep window within desktop bounds
                    final screenSize = MediaQuery.of(context).size;

                    final x = newPosition.dx.clamp(
                      0.0,
                      screenSize.width - 100.0,
                    );
                    final y = newPosition.dy.clamp(
                      0.0,
                      screenSize.height - 100.0,
                    );

                    onWindowPositionChanged(Offset(x, y));
                  },
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF21252B),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha:0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Window controls
                        Row(
                          children: [
                            // Close button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: onClose,
                            ),
                            const SizedBox(width: 8),
                            // Minimize button
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.minimize,
                                color: Colors.white70,
                                size: 18,
                              ),
                              onPressed: onMinimize,
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Window title
                        Expanded(
                          child: Text(
                            project.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Window content
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF282C34),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildProjectDetail(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  Widget _buildProjectDetail() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project image
        if (project.imageUrl.isNotEmpty)
          Container(
            height: 160,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[800],
              image: DecorationImage(
                image: NetworkImage(project.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

        // Project description
        Text(
          project.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        // Technologies used
        if (project.technologies.isNotEmpty) ...[
          Text(
            languageController.getText(
              'projects_section.technologies',
              defaultValue: 'Technologies',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                project.technologies
                    .map(
                      (tech) => Chip(
                        backgroundColor: const Color(0xFF3A3D41),
                        label: Text(
                          tech,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Project link
        if (project.url.isNotEmpty)
          ElevatedButton.icon(
            onPressed: onOpenLink,
            icon: const Icon(Icons.open_in_new),
            label: Text(
              languageController.getText(
                'projects_section.open_project',
                defaultValue: 'Open Project',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
      ],
    );
}
