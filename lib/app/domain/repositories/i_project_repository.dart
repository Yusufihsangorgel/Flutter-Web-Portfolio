import 'package:flutter_web_portfolio/app/domain/entities/project.dart';

/// Read-only project data access contract.
abstract interface class IProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectById(String id);
}
