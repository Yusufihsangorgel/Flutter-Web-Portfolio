/// Group a package belongs to. The declaration order is the reading order.
enum PortfolioPackageCategory {
  nativeFfi('native-ffi'),
  aiLlm('ai-llm'),
  server('server'),
  flutterUi('flutter-ui'),
  devTool('dev-tool');

  const PortfolioPackageCategory(this.wireValue);
  final String wireValue;

  static PortfolioPackageCategory parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () => throw FormatException('Unsupported package category: $value'),
  );
}

typedef PortfolioPackageFields = ({
  String id,
  String name,
  String description,
  Uri url,
  String version,
  int likes,
  int pubPoints,
  int downloads,
  PortfolioPackageCategory category,
  bool featured,
  List<String> topics,
  List<PackageRoadmapItem> roadmap,
  Uri? repository,
  int? maturityLevel,
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
      featured = fields.featured,
      topics = List.unmodifiable(fields.topics),
      roadmap = List.unmodifiable(fields.roadmap),
      repository = fields.repository,
      maturityLevel = fields.maturityLevel,
      proof = fields.proof {
    if (maturityLevel case final level?
        when level < minMaturityLevel || level > maxMaturityLevel) {
      throw FormatException(
        'Package "$id" maturity level must be from $minMaturityLevel to '
        '$maxMaturityLevel, got $level.',
      );
    }
  }

  static const minMaturityLevel = 1;
  static const maxMaturityLevel = 5;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'url': url.toString(),
    'version': version,
    'likes': likes,
    'pub_points': pubPoints,
    'downloads': downloads,
    'category': category.wireValue,
    'featured': featured,
    'topics': topics,
    'roadmap': [for (final value in roadmap) value.toJson()],
    'repository': repository?.toString(),
    'maturity_level': maturityLevel,
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
  final PortfolioPackageCategory category;

  /// Selected for the summary shown first; the document caps how many.
  final bool featured;
  final List<String> topics;
  final List<PackageRoadmapItem> roadmap;
  final Uri? repository;

  /// Maturity from [minMaturityLevel] to [maxMaturityLevel], if declared.
  /// The top level means a real external user drives the package.
  final int? maturityLevel;

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
