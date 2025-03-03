import 'package:get/get.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/repositories/i_project_repository.dart';

/// Ana sayfa controller'ı
class HomeController extends GetxController {
  final IProjectRepository _projectRepository;

  // Observable state değişkenleri
  final RxList<Project> projects = <Project>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  HomeController({required IProjectRepository projectRepository})
    : _projectRepository = projectRepository;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  /// Projeleri yükler
  Future<void> loadProjects() async {
    isLoading.value = true;
    error.value = '';

    try {
      final projectList = await _projectRepository.getProjects();
      projects.value = projectList;
    } catch (e) {
      error.value = 'Projeler yüklenirken hata oluştu: $e';
      print(error.value);
    } finally {
      isLoading.value = false;
    }
  }

  /// Projeleri yeniden yükler
  Future<void> refreshProjects() async {
    await loadProjects();
  }
}
