import '../entities/project.dart';

/// Proje verilerine erişim için repository interface
abstract class IProjectRepository {
  /// Tüm projeleri getirir
  Future<List<Project>> getProjects();

  /// ID'ye göre proje detayını getirir
  Future<Project> getProjectById(String id);
}
