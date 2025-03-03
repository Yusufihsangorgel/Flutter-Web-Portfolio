import '../../domain/entities/project.dart';

/// Proje entity'sinin veri modeli implementasyonu
class ProjectModel extends Project {
  ProjectModel({
    required String id,
    required String title,
    required String description,
    required List<String> technologies,
    required String imageUrl,
    String liveUrl = '',
    String githubUrl = '',
  }) : super(
         id: id,
         title: title,
         description: description,
         technologies: technologies,
         imageUrl: imageUrl,
         liveUrl: liveUrl,
         githubUrl: githubUrl,
       );

  /// JSON'dan ProjectModel oluşturur
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      technologies: List<String>.from(json['technologies']),
      imageUrl: json['imageUrl'],
      liveUrl: json['liveUrl'] ?? '',
      githubUrl: json['githubUrl'] ?? '',
    );
  }

  /// ProjectModel'den JSON oluşturur
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'technologies': technologies,
      'imageUrl': imageUrl,
      'liveUrl': liveUrl,
      'githubUrl': githubUrl,
    };
  }
}
