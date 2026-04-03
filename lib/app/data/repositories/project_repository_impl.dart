import 'package:flutter_web_portfolio/app/data/models/project_model.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_assets_provider.dart';
import 'package:flutter_web_portfolio/app/domain/entities/project.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_project_repository.dart';

/// In-memory cached project repo backed by JSON assets.
final class ProjectRepositoryImpl implements IProjectRepository {

  ProjectRepositoryImpl({required IAssetsProvider assetsProvider})
    : _assetsProvider = assetsProvider;
  final IAssetsProvider _assetsProvider;
  List<ProjectModel>? _cache;

  @override
  Future<List<Project>> getProjects() async {
    if (_cache != null) return _cache!;

    final data = await _assetsProvider.loadProjectsData();
    _cache = data.map(ProjectModel.fromJson).toList();
    return _cache!;
  }

  @override
  Future<Project> getProjectById(String id) async {
    final projects = await getProjects();
    return projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project not found: $id'),
    );
  }

}
