import '../entities/skill.dart';

abstract interface class ISkillRepository {
  Future<List<Skill>> getSkills();
  Future<List<Skill>> getSkillsByCategory(String category);
  Future<List<String>> getSkillCategories();
}
