typedef PortfolioCapabilityTranslation = ({String label, List<String> items});

final class PortfolioCapability {
  PortfolioCapability({
    required this.id,
    required this.label,
    required List<String> items,
  }) : items = List.unmodifiable(items);

  PortfolioCapability copyWith(PortfolioCapabilityTranslation changes) =>
      PortfolioCapability(id: id, label: changes.label, items: changes.items);

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'items': items};

  final String id;
  final String label;
  final List<String> items;
}
