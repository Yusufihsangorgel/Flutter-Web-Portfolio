typedef PortfolioPackageFields = ({
  String id,
  String name,
  String description,
  Uri url,
  String version,
  int likes,
  int pubPoints,
  int downloads,
  String category,
  List<String> topics,
  List<PackageRoadmapItem> roadmap,
  Uri? repository,
  String? maturity,
  String? proof,
});

/// A published pub.dev package. Factual record, not localized.
final class PortfolioPackage {
  PortfolioPackage(PortfolioPackageFields fields)
    : id = fields.id,
      name = fields.name,
      description = fields.description,
      url = fields.url,
      version = fields.version,
      likes = fields.likes,
      pubPoints = fields.pubPoints,
      downloads = fields.downloads,
      category = fields.category,
      topics = List.unmodifiable(fields.topics),
      roadmap = List.unmodifiable(fields.roadmap),
      repository = fields.repository,
      maturity = fields.maturity,
      proof = fields.proof;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url.toString(),
    'version': version,
    'likes': likes,
    'pub_points': pubPoints,
    'downloads': downloads,
    'category': category,
    'topics': topics,
    'roadmap': [for (final value in roadmap) value.toJson()],
    'repository': repository?.toString(),
    'maturity': maturity,
    'proof': proof,
  };

  final String id;
  final String name;
  final String description;
  final Uri url;
  final String version;
  final int likes;
  final int pubPoints;
  final int downloads;
  final String category;
  final List<String> topics;
  final List<PackageRoadmapItem> roadmap;
  final Uri? repository;

  /// Rung on the portfolio's maturity ladder (L1..L5), if declared.
  final String? maturity;

  /// One measured claim that carries the package's case, if declared.
  final String? proof;
}

/// A roadmap entry on a package. [status] is one of `done`, `doing`, `next`,
/// or `waiting`; anything else fails construction.
final class PackageRoadmapItem {
  PackageRoadmapItem({required this.title, required this.status}) {
    const allowed = {'done', 'doing', 'next', 'waiting'};
    if (!allowed.contains(status)) {
      throw FormatException('Unknown roadmap status "$status".');
    }
  }

  Map<String, Object?> toJson() => {'title': title, 'status': status};

  final String title;
  final String status;
}
