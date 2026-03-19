final class Skill {

  const Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiency,
    this.iconPath = '',
  });
  final String id;
  final String name;
  final String category;
  final double proficiency;
  final String iconPath;
}
