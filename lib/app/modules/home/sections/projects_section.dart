import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';

class ProjectsSection extends StatefulWidget {
  const ProjectsSection({super.key});

  @override
  State<ProjectsSection> createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection>
    with SingleTickerProviderStateMixin {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final RxList<ProjectWindowModel> _projects = <ProjectWindowModel>[].obs;
  final RxList<ProjectWindowModel> _openProjects = <ProjectWindowModel>[].obs;
  int _currentDesktopIndex = 0;
  DateTime _lastTimeCheck = DateTime.now();
  bool _showClock = true;
  Timer? _clockTimer;
  Timer? _projectOpenTimer;
  int _openProjectIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeProjects();

    // Update clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _lastTimeCheck = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _projectOpenTimer?.cancel();
    super.dispose();
  }

  void _initializeProjects() {
    // Load projects from languageController
    final projectsData = languageController.cvData['projects'] ?? [];

    _projects.clear();

    for (var project in projectsData) {
      _projects.add(
        ProjectWindowModel(
          id: project['id'] ?? UniqueKey().toString(),
          title: project['title'] ?? 'Project',
          description: project['description'] ?? '',
          technologies: List<String>.from(project['technologies'] ?? []),
          imageUrl: project['image'] ?? '',
          url: _extractUrl(project),
          windowPosition: Offset(
            100 + (math.Random().nextDouble() * 100),
            100 + (math.Random().nextDouble() * 100),
          ),
          windowSize: const Size(600, 400),
          isOpen: false,
          isMinimized: false,
          zIndex: 0,
        ),
      );
    }
  }

  String _extractUrl(Map<dynamic, dynamic> project) {
    if (project['url'] is String) {
      return project['url'] as String;
    } else if (project['url'] is Map) {
      final urls = project['url'] as Map;
      for (final key in ['website', 'google_play', 'app_store']) {
        if (urls.containsKey(key)) {
          return urls[key] as String;
        }
      }
    }
    return '';
  }

  void _openProject(ProjectWindowModel project) {
    setState(() {
      if (!_openProjects.contains(project)) {
        // Find max zIndex to put this window on top
        int maxZIndex = 0;
        for (var openProject in _openProjects) {
          if (openProject.zIndex > maxZIndex) {
            maxZIndex = openProject.zIndex;
          }
        }

        project.isOpen = true;
        project.isMinimized = false;
        project.zIndex = maxZIndex + 1;
        _openProjects.add(project);
      } else if (project.isMinimized) {
        project.isMinimized = false;
        _bringToFront(project);
      } else {
        _bringToFront(project);
      }
    });
  }

  void _minimizeProject(ProjectWindowModel project) {
    setState(() {
      project.isMinimized = true;
    });
  }

  void _closeProject(ProjectWindowModel project) {
    setState(() {
      _openProjects.remove(project);
      project.isOpen = false;
      project.isMinimized = false;
    });
  }

  void _bringToFront(ProjectWindowModel project) {
    if (!_openProjects.contains(project)) return;

    setState(() {
      // Find the max zIndex
      int maxZIndex = 0;
      for (var p in _openProjects) {
        if (p.zIndex > maxZIndex) {
          maxZIndex = p.zIndex;
        }
      }

      // Only update if not already on top
      if (project.zIndex != maxZIndex) {
        project.zIndex = maxZIndex + 1;
      }
    });
  }

  void _sequentiallyOpenProjects() {
    // Reset all projects
    for (var project in _projects) {
      project.isOpen = false;
      project.isMinimized = false;
    }
    _openProjects.clear();

    // Start opening sequence
    _openProjectIndex = -1;
    _projectOpenTimer?.cancel();

    _projectOpenTimer = Timer.periodic(const Duration(milliseconds: 300), (
      timer,
    ) {
      setState(() {
        _openProjectIndex++;

        if (_openProjectIndex >= _projects.length) {
          timer.cancel();
          return;
        }

        _openProject(_projects[_openProjectIndex]);
      });
    });
  }

  Future<void> _launchProjectUrl(String url) async {
    if (url.isEmpty) return;

    try {
      // Ensure url has proper scheme
      String urlString = url;
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }

      final uri = Uri.parse(urlString);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isWideScreen = screenWidth > 800;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight * 0.8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 100 : 20,
          vertical: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            SectionTitle(
              title: languageController.getText(
                'projects_section.title',
                defaultValue: 'Projects',
              ),
              subtitle: languageController.getText(
                'projects_section.description',
                defaultValue: 'Take a look at some of my projects.',
              ),
            ),

            const SizedBox(height: 20),

            // Desktop-like interface
            Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: isWideScreen ? screenWidth * 0.8 : screenWidth,
                  height: 600,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D21),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // Desktop taskbar
                        TaskBar(
                          onMenuPressed: _sequentiallyOpenProjects,
                          time: _lastTimeCheck,
                          showClock: _showClock,
                          openProjects: _openProjects,
                          onProjectSelected: (project) {
                            if (project.isMinimized) {
                              _openProject(project);
                            }
                          },
                        ),

                        // Desktop content
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Desktop background
                              DesktopBackground(
                                currentIndex: _currentDesktopIndex,
                              ),

                              // Desktop icons
                              Positioned(
                                left: 20,
                                top: 20,
                                child: Column(
                                  children:
                                      _projects
                                          .map(
                                            (project) => DesktopIcon(
                                              title: project.title,
                                              iconData: Icons.folder,
                                              onTap:
                                                  () => _openProject(project),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),

                              // Project windows
                              ..._openProjects.map((project) {
                                return Positioned(
                                  left: project.windowPosition.dx,
                                  top: project.windowPosition.dy,
                                  child: Visibility(
                                    visible: !project.isMinimized,
                                    maintainState: true,
                                    maintainAnimation: true,
                                    maintainSize: true,
                                    child: ProjectWindow(
                                      key: ValueKey('project-${project.id}'),
                                      project: project,
                                      onWindowPositionChanged: (position) {
                                        setState(() {
                                          project.windowPosition = position;
                                        });
                                      },
                                      onClose: () => _closeProject(project),
                                      onMinimize:
                                          () => _minimizeProject(project),
                                      onTap: () => _bringToFront(project),
                                      onOpenLink:
                                          () => _launchProjectUrl(project.url),
                                      zIndex: project.zIndex,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskBar extends StatelessWidget {
  final VoidCallback onMenuPressed;
  final DateTime time;
  final bool showClock;
  final List<ProjectWindowModel> openProjects;
  final Function(ProjectWindowModel) onProjectSelected;

  const TaskBar({
    Key? key,
    required this.onMenuPressed,
    required this.time,
    required this.showClock,
    required this.openProjects,
    required this.onProjectSelected,
  }) : super(key: key);

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

class DesktopBackground extends StatelessWidget {
  final int currentIndex;

  const DesktopBackground({Key? key, required this.currentIndex})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Colors.transparent, // Tamamen şeffaf, CosmicBackground görünecek
            Colors.transparent, // Tamamen şeffaf, CosmicBackground görünecek
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SizedBox.expand(), // Yıldızları kaldırdık
    );
  }
}

class DesktopIcon extends StatelessWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  const DesktopIcon({
    Key? key,
    required this.title,
    required this.iconData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onTap, // Usually desktop icons are opened with double-click
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectWindow extends StatelessWidget {
  final ProjectWindowModel project;
  final Function(Offset) onWindowPositionChanged;
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  final VoidCallback onTap;
  final VoidCallback onOpenLink;
  final int zIndex;

  const ProjectWindow({
    Key? key,
    required this.project,
    required this.onWindowPositionChanged,
    required this.onClose,
    required this.onMinimize,
    required this.onTap,
    required this.onOpenLink,
    required this.zIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  color: Colors.black.withOpacity(0.5),
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
                    final windowWidth = project.windowSize.width;
                    final windowHeight = project.windowSize.height;

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
                          color: Colors.black.withOpacity(0.3),
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
                    decoration: BoxDecoration(
                      color: const Color(0xFF282C34),
                      borderRadius: const BorderRadius.only(
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
  }

  Widget _buildProjectDetail() {
    return Column(
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
          const Text(
            'Technologies',
            style: TextStyle(
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
            label: const Text('Open Project'),
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
}

class ProjectWindowModel {
  final String id;
  final String title;
  final String description;
  final List<String> technologies;
  final String imageUrl;
  final String url;
  Offset windowPosition;
  final Size windowSize;
  bool isOpen;
  bool isMinimized;
  int zIndex;

  ProjectWindowModel({
    required this.id,
    required this.title,
    required this.description,
    required this.technologies,
    required this.imageUrl,
    required this.url,
    required this.windowPosition,
    required this.windowSize,
    required this.isOpen,
    required this.isMinimized,
    required this.zIndex,
  });
}
