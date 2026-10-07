typedef PortfolioLinkTranslation = ({String label});

final class PortfolioLink {
  const PortfolioLink({
    required this.id,
    required this.label,
    required this.url,
  });

  PortfolioLink copyWith(PortfolioLinkTranslation changes) =>
      PortfolioLink(id: id, label: changes.label, url: url);

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'url': url.toString(),
  };

  final String id;
  final String label;
  final Uri url;
}
