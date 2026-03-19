final class Experience {
  final String id;
  final String title;
  final String company;
  final String period;
  final String location;
  final List<String> responsibilities;
  final List<String> technologies;

  const Experience({
    required this.id,
    required this.title,
    required this.company,
    required this.period,
    required this.location,
    required this.responsibilities,
    required this.technologies,
  });
}
