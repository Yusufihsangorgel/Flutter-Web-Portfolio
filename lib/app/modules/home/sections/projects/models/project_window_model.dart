import 'dart:ui';

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
