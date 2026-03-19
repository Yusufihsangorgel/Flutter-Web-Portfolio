import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/widgets/animated_entrance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';

import 'models/project_window_model.dart';
import 'widgets/desktop_environment.dart';
import 'widgets/task_bar.dart';
import 'widgets/project_window.dart';

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
  final int _currentDesktopIndex = 0;
  DateTime _lastTimeCheck = DateTime.now();
  final bool _showClock = true;
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

    if (projectsData.isEmpty) {
      // No project data available
      return;
    }

    for (var project in projectsData) {
      final String title =
          project['title'] ??
          languageController.getText(
            'projects_section.untitled_project',
            defaultValue: 'Project',
          );

      final String description = project['description'] ?? '';
      final List<String> technologies = _extractTechnologies(project);
      final String imageUrl = project['image'] ?? '';
      final String url = _extractUrl(project);

      _projects.add(
        ProjectWindowModel(
          id: project['id'] ?? UniqueKey().toString(),
          title: title,
          description: description,
          technologies: technologies,
          imageUrl: imageUrl,
          url: url,
          windowPosition: _generateRandomPosition(),
          windowSize: const Size(600, 400),
          isOpen: false,
          isMinimized: false,
          zIndex: 0,
        ),
      );
    }
  }

  /// Extracts technologies from a project map.
  List<String> _extractTechnologies(Map<dynamic, dynamic> project) {
    if (project.containsKey('technologies') &&
        project['technologies'] is List) {
      return List<String>.from(project['technologies']);
    }

    // Try to extract technologies from the description
    if (project.containsKey('description') &&
        project['description'] is String) {
      final String desc = project['description'];
      final List<String> possibleTechs = [];

      // Check for common technology keywords
      final techKeywords = [
        'Flutter',
        'React',
        'Node.js',
        'JavaScript',
        'TypeScript',
        'HTML',
        'CSS',
        'MongoDB',
        'Express',
        'Firebase',
        'AWS',
        'REST',
        'API',
        'GetX',
        'MVVM',
        'SQLite',
        'Drift',
      ];

      for (final tech in techKeywords) {
        if (desc.contains(tech)) {
          possibleTechs.add(tech);
        }
      }

      return possibleTechs;
    }

    return [];
  }

  /// Generates a random window position.
  Offset _generateRandomPosition() => Offset(
      100 + (math.Random().nextDouble() * 100),
      100 + (math.Random().nextDouble() * 100),
    );

  String _extractUrl(Map<dynamic, dynamic> project) {
    if (project['url'] is String) {
      return project['url'] as String;
    } else if (project['url'] is Map) {
      final urls = project['url'] as Map;
      // Priority order: website > google_play > app_store
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
      }
    } catch (_) {
      // URL launch failed silently
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
                defaultValue: 'My Projects',
              ),
              subtitle: languageController.getText(
                'projects_section.description',
                defaultValue: 'Major projects and works I\'ve completed',
              ),
            ),

            const SizedBox(height: 20),

            // Desktop-like interface
            Center(
              child: AnimatedEntrance.fadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: isWideScreen ? screenWidth * 0.8 : screenWidth,
                  height: 600,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D21),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withValues(alpha:0.2),
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
                              ..._openProjects.map((project) => Positioned(
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
                                      languageController: languageController,
                                    ),
                                  ),
                                )),
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
