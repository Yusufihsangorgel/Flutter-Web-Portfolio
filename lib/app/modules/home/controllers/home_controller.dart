import 'dart:developer' as dev;

import 'package:get/get.dart';
import '../../../domain/entities/project.dart';
import '../../../domain/repositories/i_project_repository.dart';

class HomeController extends GetxController {

  HomeController({required IProjectRepository projectRepository})
    : _projectRepository = projectRepository;
  final IProjectRepository _projectRepository;

  final RxList<Project> projects = <Project>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    error.value = '';

    try {
      final projectList = await _projectRepository.getProjects();
      projects.value = projectList;
    } catch (e) {
      error.value = 'Failed to load projects: $e';
      dev.log(error.value, name: 'HomeController', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProjects() async => loadProjects();
}
