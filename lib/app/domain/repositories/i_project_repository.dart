import '../entities/project.dart';

abstract interface class IProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectById(String id);
}
