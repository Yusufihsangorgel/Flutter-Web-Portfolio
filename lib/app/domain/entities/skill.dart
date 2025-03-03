/// Beceri detaylarını tutan entity sınıfı
class Skill {
  final String id;
  final String name;
  final String category;
  final double proficiency; // 0.0 - 1.0 arası
  final String iconPath;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.proficiency,
    this.iconPath = '',
  });
}
