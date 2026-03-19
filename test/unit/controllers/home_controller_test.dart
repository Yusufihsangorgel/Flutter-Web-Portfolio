import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/modules/home/controllers/home_controller.dart';
import 'package:flutter_web_portfolio/app/domain/entities/project.dart';
import 'package:flutter_web_portfolio/app/domain/repositories/i_project_repository.dart';

class _MockProjectRepository implements IProjectRepository {
  final List<Project> _projects;
  final bool shouldFail;

  _MockProjectRepository({List<Project>? projects, this.shouldFail = false})
    : _projects = projects ?? [];

  @override
  Future<List<Project>> getProjects() async {
    if (shouldFail) throw Exception('Network error');
    return _projects;
  }

  @override
  Future<Project> getProjectById(String id) async {
    return _projects.firstWhere((p) => p.id == id);
  }
}

void main() {
  late HomeController controller;

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() => Get.reset());

  group('HomeController', () {
    test('starts with empty projects and loading false after init', () async {
      final repo = _MockProjectRepository(projects: []);
      controller = HomeController(projectRepository: repo);
      Get.put(controller);

      // Wait for onInit to complete
      await Future.delayed(Duration.zero);

      expect(controller.projects, isEmpty);
      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isEmpty);
    });

    test('loads projects successfully', () async {
      final mockProjects = [
        const Project(
          id: '1',
          title: 'Test Project',
          description: 'Description',
          technologies: ['Flutter'],
          imageUrl: 'img.png',
        ),
      ];
      final repo = _MockProjectRepository(projects: mockProjects);
      controller = HomeController(projectRepository: repo);
      Get.put(controller);

      await Future.delayed(Duration.zero);

      expect(controller.projects.length, equals(1));
      expect(controller.projects.first.title, equals('Test Project'));
    });

    test('sets error on repository failure', () async {
      final repo = _MockProjectRepository(shouldFail: true);
      controller = HomeController(projectRepository: repo);
      Get.put(controller);

      await Future.delayed(Duration.zero);

      expect(controller.error.value, contains('Failed to load projects'));
      expect(controller.projects, isEmpty);
    });

    test('refreshProjects delegates to loadProjects', () async {
      final repo = _MockProjectRepository(projects: []);
      controller = HomeController(projectRepository: repo);
      Get.put(controller);

      await controller.refreshProjects();
      expect(controller.isLoading.value, isFalse);
    });
  });
}
