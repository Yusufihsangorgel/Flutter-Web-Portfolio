import 'package:get/get.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../models/project_model.dart';
import '../providers/assets_provider.dart';

final class ProjectRepositoryImpl implements IProjectRepository {
  final AssetsProvider _assetsProvider;
  final RxList<ProjectModel> _cache = <ProjectModel>[].obs;

  ProjectRepositoryImpl({required AssetsProvider assetsProvider})
    : _assetsProvider = assetsProvider;

  @override
  Future<List<Project>> getProjects() async {
    if (_cache.isNotEmpty) return _cache;

    final data = await _assetsProvider.loadProjectsData();
    _cache.value = data.map(ProjectModel.fromJson).toList();
    return _cache;
  }

  @override
  Future<Project> getProjectById(String id) async {
    final projects = await getProjects();
    return projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project not found: $id'),
    );
  }

  void clearCache() => _cache.clear();
}
