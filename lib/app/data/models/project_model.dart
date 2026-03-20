import 'package:flutter_web_portfolio/app/domain/entities/project.dart';

/// JSON-backed project data model.
final class ProjectModel extends Project {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.description,
    required super.technologies,
    required super.imageUrl,
    super.liveUrl,
    super.githubUrl,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    technologies: List<String>.from((json['technologies'] as List?) ?? []),
    imageUrl: json['imageUrl'] as String? ?? '',
    liveUrl: json['liveUrl'] as String? ?? '',
    githubUrl: json['githubUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'technologies': technologies,
    'imageUrl': imageUrl,
    'liveUrl': liveUrl,
    'githubUrl': githubUrl,
  };
}
