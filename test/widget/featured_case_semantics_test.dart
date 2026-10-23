import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/featured_case.dart';

import '../helpers/portfolio_fixture.dart';
import '../helpers/project_atlas_labels_fixture.dart';

final _labels = projectAtlasLabelsFixture();

void main() {
  testWidgets(
    'featured case exposes a compact title heading and separate story',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final system = loadPortfolioFixture().featuredSystems.first;
      final semantics = tester.ensureSemantics();

      try {
        for (final width in [1440.0, 390.0]) {
          tester.view.physicalSize = Size(width, 3200);
          await tester.pumpWidget(
            withPortfolioFixtureAssets(
              child: MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: FeaturedCase(
                      system: system,
                      index: 0,
                      labels: _labels,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final headings = find.semantics.byPredicate(
            (node) =>
                node.flagsCollection.isHeader &&
                node.getSemanticsData().headingLevel == 3,
          );
          expect(headings, findsOne, reason: 'viewport width $width');
          final heading = headings.evaluate().single;
          expect(heading.label, system.name);
          expect(heading.rect.height, lessThan(200));

          _expectSeparateNarrative(system);
          _expectNamedEvidenceLinks(system);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );
}

void _expectSeparateNarrative(PortfolioFeaturedSystem system) {
  expect(
    find.semantics.byPredicate(
      (node) => node.label == '${_labels.caseLabel.toUpperCase()} 01',
    ),
    findsOne,
  );
  final summary = find.semantics.byPredicate(
    (node) => node.label.contains(system.summary),
  );
  expect(summary, findsOne);
  expect(summary.evaluate().single.label, system.summary);
  expect(
    find.semantics.byPredicate(
      (node) => node.label == system.kind && !node.flagsCollection.isHeader,
    ),
    findsOne,
  );
  expect(
    find.semantics.byPredicate((node) => node.label == system.year),
    findsOne,
  );
  for (final label in [_labels.challenge, _labels.approach, _labels.outcome]) {
    expect(find.semantics.byPredicate((node) => node.label == label), findsOne);
  }
  for (final value in [system.challenge, system.approach, system.outcome]) {
    expect(find.semantics.byPredicate((node) => node.label == value), findsOne);
  }
}

void _expectNamedEvidenceLinks(PortfolioFeaturedSystem system) {
  final names = <String>{};
  for (final evidence in system.evidence) {
    final name = '${_labels.openEvidence}: ${system.name}, ${evidence.label}';
    expect(names.add(name), isTrue);
    final links = find.semantics.byPredicate(
      (node) => node.flagsCollection.isLink && node.label == name,
    );
    expect(links, findsOne);
    expect(links.evaluate().single.getSemanticsData().linkUrl, evidence.url);
  }
}
