import '../entities/experience.dart';

abstract interface class IExperienceRepository {
  Future<List<Experience>> getExperiences();
  Future<Experience> getExperienceById(String id);
}
