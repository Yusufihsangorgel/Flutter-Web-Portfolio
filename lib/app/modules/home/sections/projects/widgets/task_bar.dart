import 'package:flutter/material.dart';

import '../models/project_window_model.dart';

/// The taskbar displayed at the top of the desktop environment.
/// Contains a menu button, tabs for open projects, and a clock.
class TaskBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final DateTime time;
  final bool showClock;
  final List<ProjectWindowModel> openProjects;
  final Function(ProjectWindowModel) onProjectSelected;

  const TaskBar({
    super.key,
    required this.onMenuPressed,
    required this.time,
    required this.showClock,
    required this.openProjects,
    required this.onProjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D31),
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Start Button
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
            tooltip: 'Show All Projects',
            onPressed: onMenuPressed,
          ),

          const SizedBox(width: 10),

          // Open project tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    openProjects.map((project) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => onProjectSelected(project),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  project.isMinimized
                                      ? const Color(0xFF3A3D41)
                                      : const Color(0xFF4A4D51),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  project.title,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Clock
          if (showClock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
