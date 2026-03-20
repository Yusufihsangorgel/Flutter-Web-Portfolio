/// Core project entity — id, title, description, tech stack, URLs.
base class Project {

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.technologies,
    required this.imageUrl,
    this.liveUrl = '',
    this.githubUrl = '',
  });
  final String id;
  final String title;
  final String description;
  final List<String> technologies;
  final String imageUrl;
  final String liveUrl;
  final String githubUrl;
}
