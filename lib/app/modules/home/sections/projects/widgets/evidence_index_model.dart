import 'package:flutter/foundation.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_labels.dart';

/// Supporting systems, the one currently previewed, and how to change it.
@immutable
final class EvidenceIndexModel {
  const EvidenceIndexModel({
    required this.systems,
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final List<PortfolioSupportingSystem> systems;
  final PortfolioSupportingSystem selected;
  final ProjectAtlasLabels labels;
  final ValueChanged<PortfolioSupportingSystem> onSelect;

  /// The system with [id], or the first system when [id] is no longer listed.
  static PortfolioSupportingSystem resolve(
    List<PortfolioSupportingSystem> systems,
    String id,
  ) => systems.firstWhere(
    (system) => system.id == id,
    orElse: () => systems.first,
  );

  bool isSelected(PortfolioSupportingSystem system) => system.id == selected.id;

  String groupLabel(PortfolioSystemGroup group) => switch (group) {
    PortfolioSystemGroup.shippedProduct => labels.shippedProducts,
    PortfolioSystemGroup.openEngineering => labels.openEngineering,
  };
}
