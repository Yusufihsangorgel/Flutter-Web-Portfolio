import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/contribution.dart';

PortfolioContribution parsePortfolioContribution(Map<String, dynamic> json) =>
    PortfolioContribution((
      id: requiredString(json, 'id'),
      project: requiredString(json, 'project'),
      status: ContributionStatus.parse(requiredString(json, 'status')),
      date: DateTime.parse(requiredString(json, 'date')),
      title: requiredString(json, 'title'),
      problem: requiredString(json, 'problem'),
      change: requiredString(json, 'change'),
      url: requiredUri(json, 'url'),
      featured: requiredBool(json, 'featured'),
      issueUrl: optionalUri(json, 'issue_url'),
      eventOrderLab: switch (optionalObject(json, 'event_order_lab')) {
        final value? => _parsePortfolioEventOrderLab(value),
        null => null,
      },
    ));

PortfolioEventOrderLab _parsePortfolioEventOrderLab(Map<String, dynamic> json) {
  final lab = PortfolioEventOrderLab(
    title: requiredString(json, 'title'),
    events: requiredObjects(
      json,
      'events',
    ).map(_parsePortfolioEventOrderItem).toList(),
    baseline: _parsePortfolioEventSequence(requiredObject(json, 'baseline')),
    withPatch: _parsePortfolioEventSequence(requiredObject(json, 'with_patch')),
  )..validate();
  return lab;
}

PortfolioEventOrderItem _parsePortfolioEventOrderItem(
  Map<String, dynamic> json,
) => PortfolioEventOrderItem(
  id: requiredString(json, 'id'),
  label: requiredString(json, 'label'),
);

PortfolioEventSequence _parsePortfolioEventSequence(
  Map<String, dynamic> json,
) => PortfolioEventSequence(
  summary: requiredString(json, 'summary'),
  order: requiredStrings(json, 'order'),
  gap: switch (optionalObject(json, 'gap')) {
    final value? => _parsePortfolioEventGap(value),
    null => null,
  },
);

PortfolioEventGap _parsePortfolioEventGap(Map<String, dynamic> json) =>
    PortfolioEventGap(
      after: requiredString(json, 'after'),
      before: requiredString(json, 'before'),
      label: requiredString(json, 'label'),
    );
