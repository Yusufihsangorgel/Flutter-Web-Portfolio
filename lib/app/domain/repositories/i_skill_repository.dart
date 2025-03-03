import '../entities/skill.dart';

/// Beceri verilerine erişim için repository interface
abstract class ISkillRepository {
  /// Tüm becerileri getirir
  Future<List<Skill>> getSkills();

  /// Kategori bazında becerileri getirir
  Future<List<Skill>> getSkillsByCategory(String category);

  /// Beceri kategorilerini getirir
  Future<List<String>> getSkillCategories();
}
