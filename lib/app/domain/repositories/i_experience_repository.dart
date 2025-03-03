import '../entities/experience.dart';

/// Deneyim verilerine erişim için repository interface
abstract class IExperienceRepository {
  /// Tüm deneyimleri getirir
  Future<List<Experience>> getExperiences();

  /// ID'ye göre deneyim detayını getirir
  Future<Experience> getExperienceById(String id);
}
