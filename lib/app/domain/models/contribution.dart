import 'package:flutter_web_portfolio/app/domain/models/model_validation.dart';

enum ContributionStatus {
  merged('merged'),
  underReview('under_review');

  const ContributionStatus(this.wireValue);
  final String wireValue;

  static ContributionStatus parse(String value) => values.firstWhere(
    (entry) => entry.wireValue == value,
    orElse: () =>
        throw FormatException('Unsupported contribution status: $value'),
  );
}

typedef PortfolioContributionTranslation = ({
  String title,
  String problem,
  String change,
  PortfolioEventOrderLab? eventOrderLab,
});

typedef PortfolioContributionFields = ({
  String id,
  String project,
  ContributionStatus status,
  DateTime date,
  String title,
  String problem,
  String change,
  Uri url,
  bool featured,
  Uri? issueUrl,
  PortfolioEventOrderLab? eventOrderLab,
});

final class PortfolioContribution {
  PortfolioContribution(PortfolioContributionFields fields)
    : id = fields.id,
      project = fields.project,
      status = fields.status,
      date = fields.date,
      title = fields.title,
      problem = fields.problem,
      change = fields.change,
      url = fields.url,
      featured = fields.featured,
      issueUrl = fields.issueUrl,
      eventOrderLab = fields.eventOrderLab;

  PortfolioContribution copyWith(PortfolioContributionTranslation changes) =>
      PortfolioContribution((
        id: id,
        project: project,
        status: status,
        date: date,
        title: changes.title,
        problem: changes.problem,
        change: changes.change,
        url: url,
        featured: featured,
        issueUrl: issueUrl,
        eventOrderLab: changes.eventOrderLab,
      ));

  Map<String, Object?> toJson() => {
    'id': id,
    'project': project,
    'status': status.wireValue,
    'date': date.toIso8601String(),
    'title': title,
    'problem': problem,
    'change': change,
    'url': url.toString(),
    'featured': featured,
    'issue_url': issueUrl?.toString(),
    'event_order_lab': eventOrderLab?.toJson(),
  };

  final String id;
  final String project;
  final ContributionStatus status;
  final DateTime date;
  final String title;
  final String problem;
  final String change;
  final Uri url;
  final bool featured;
  final Uri? issueUrl;
  final PortfolioEventOrderLab? eventOrderLab;
}

typedef PortfolioEventOrderLabTranslation = ({
  String title,
  List<PortfolioEventOrderItem> events,
  PortfolioEventSequence baseline,
  PortfolioEventSequence withPatch,
});

/// A content-authored comparison of two orderings of the same events: the
/// baseline carries one risk gap that the patched ordering closes.
final class PortfolioEventOrderLab {
  PortfolioEventOrderLab({
    required this.title,
    required List<PortfolioEventOrderItem> events,
    required this.baseline,
    required this.withPatch,
  }) : events = List.unmodifiable(events);

  PortfolioEventOrderLab copyWith(PortfolioEventOrderLabTranslation changes) =>
      PortfolioEventOrderLab(
        title: changes.title,
        events: changes.events,
        baseline: changes.baseline,
        withPatch: changes.withPatch,
      );

  Map<String, Object?> toJson() => {
    'title': title,
    'events': [for (final value in events) value.toJson()],
    'baseline': baseline.toJson(),
    'with_patch': withPatch.toJson(),
  };

  final String title;
  final List<PortfolioEventOrderItem> events;
  final PortfolioEventSequence baseline;
  final PortfolioEventSequence withPatch;

  PortfolioEventOrderItem eventById(String id) =>
      events.firstWhere((event) => event.id == id);

  void validate() {
    if (events.length < 3) {
      throw const FormatException(
        'An event-order lab requires at least three events.',
      );
    }
    assertUnique('event-order lab event', events.map((event) => event.id));
    final eventIds = events.map((event) => event.id).toSet();
    for (final sequence in [baseline, withPatch]) {
      if (sequence.order.length < 2 ||
          sequence.order.toSet().length != sequence.order.length ||
          sequence.order.any((id) => !eventIds.contains(id))) {
        throw const FormatException(
          'Event-order sequences require unique, declared event ids.',
        );
      }
    }
    final usedIds = {...baseline.order, ...withPatch.order};
    if (!usedIds.containsAll(eventIds) || usedIds.length != eventIds.length) {
      throw const FormatException(
        'Every declared event must be used by an event-order sequence.',
      );
    }
    if (sameStrings(baseline.order, withPatch.order)) {
      throw const FormatException(
        'Baseline and patched event orders must differ.',
      );
    }

    final gap = baseline.gap;
    if (gap == null || withPatch.gap != null) {
      throw const FormatException(
        'Only the baseline sequence must declare one risk gap.',
      );
    }
    final baselineAfter = baseline.order.indexOf(gap.after);
    final baselineBefore = baseline.order.indexOf(gap.before);
    final patchedAfter = withPatch.order.indexOf(gap.after);
    final patchedBefore = withPatch.order.indexOf(gap.before);
    if (baselineAfter < 0 ||
        baselineBefore != baselineAfter + 1 ||
        patchedBefore < 0 ||
        patchedAfter < 0 ||
        patchedBefore >= patchedAfter) {
      throw const FormatException(
        'The patched order must close the baseline risk gap.',
      );
    }
  }
}

typedef PortfolioEventOrderItemTranslation = ({String label});

final class PortfolioEventOrderItem {
  const PortfolioEventOrderItem({required this.id, required this.label});

  PortfolioEventOrderItem copyWith(
    PortfolioEventOrderItemTranslation changes,
  ) => PortfolioEventOrderItem(id: id, label: changes.label);

  Map<String, Object?> toJson() => {'id': id, 'label': label};

  final String id;
  final String label;
}

typedef PortfolioEventSequenceTranslation = ({
  String summary,
  PortfolioEventGap? gap,
});

final class PortfolioEventSequence {
  PortfolioEventSequence({
    required this.summary,
    required List<String> order,
    this.gap,
  }) : order = List.unmodifiable(order);

  PortfolioEventSequence copyWith(PortfolioEventSequenceTranslation changes) =>
      PortfolioEventSequence(
        summary: changes.summary,
        order: order,
        gap: changes.gap,
      );

  Map<String, Object?> toJson() => {
    'summary': summary,
    'order': order,
    'gap': gap?.toJson(),
  };

  final String summary;
  final List<String> order;
  final PortfolioEventGap? gap;
}

typedef PortfolioEventGapTranslation = ({String label});

final class PortfolioEventGap {
  const PortfolioEventGap({
    required this.after,
    required this.before,
    required this.label,
  });

  PortfolioEventGap copyWith(PortfolioEventGapTranslation changes) =>
      PortfolioEventGap(after: after, before: before, label: changes.label);

  Map<String, Object?> toJson() => {
    'after': after,
    'before': before,
    'label': label,
  };

  final String after;
  final String before;
  final String label;
}
