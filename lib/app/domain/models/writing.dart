enum PortfolioWritingSourceKind {
  rss('rss'),
  devto('devto');

  const PortfolioWritingSourceKind(this.wireValue);
  final String wireValue;

  static PortfolioWritingSourceKind parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported writing source kind: $value'),
  );
}

typedef PortfolioWritingSourceFields = ({
  String id,
  String label,
  PortfolioWritingSourceKind kind,
  Uri url,
  Uri profileUrl,
});

/// A feed the owner's writing is fetched from: an RSS/Atom blog feed or the
/// dev.to articles API. Factual, not localized.
final class PortfolioWritingSource {
  PortfolioWritingSource(PortfolioWritingSourceFields fields)
    : id = fields.id,
      label = fields.label,
      kind = fields.kind,
      url = fields.url,
      profileUrl = fields.profileUrl;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.wireValue,
    'url': url.toString(),
    'profile_url': profileUrl.toString(),
  };

  final String id;
  final String label;
  final PortfolioWritingSourceKind kind;
  final Uri url;
  final Uri profileUrl;
}

/// One published article, aggregated from a [PortfolioWritingSource].
/// Factual, not localized.
final class PortfolioWritingEntry {
  const PortfolioWritingEntry({
    required this.title,
    required this.url,
    required this.source,
    required this.date,
  });

  Map<String, Object?> toJson() => {
    'title': title,
    'url': url.toString(),
    'source': source,
    'date': date.toIso8601String(),
  };

  final String title;
  final Uri url;

  /// The [PortfolioWritingSource.id] this entry was fetched from.
  final String source;
  final DateTime date;
}
