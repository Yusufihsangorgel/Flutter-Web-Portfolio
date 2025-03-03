import 'package:get/get.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/i_project_repository.dart';
import '../models/project_model.dart';
import '../providers/assets_provider.dart';

/// IProjectRepository implementasyonu
class ProjectRepositoryImpl implements IProjectRepository {
  final AssetsProvider _assetsProvider;

  // Projeleri önbelleğe almak için
  final RxList<ProjectModel> _cachedProjects = <ProjectModel>[].obs;

  ProjectRepositoryImpl({required AssetsProvider assetsProvider})
    : _assetsProvider = assetsProvider;

  @override
  Future<List<Project>> getProjects() async {
    // Önbellekte projeler varsa onları döndür
    if (_cachedProjects.isNotEmpty) {
      return _cachedProjects;
    }

    // Yoksa asset'ten yükle
    final data = await _assetsProvider.loadProjectsData();
    _cachedProjects.value =
        data.map((json) => ProjectModel.fromJson(json)).toList();
    return _cachedProjects;
  }

  @override
  Future<Project> getProjectById(String id) async {
    // Önce tüm projeleri al
    final projects = await getProjects();

    // ID'ye göre projeyi bul
    final project = projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Proje bulunamadı: $id'),
    );

    return project;
  }

  /// Önbelleği temizler
  void clearCache() {
    _cachedProjects.clear();
  }
}
