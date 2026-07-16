import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  group('PortfolioDocument', () {
    test('loads the verified canonical content manifest', () {
      final manifest = _manifest();
      final document = PortfolioDocument.fromJson(manifest);
      final profile = manifest['profile']! as Map<String, dynamic>;
      final displayName = profile['display_name']! as Map<String, dynamic>;

      expect(document.schemaVersion, 6);
      expect(document.contentVersion, manifest['content_version']);
      expect(document.profile.name, profile['name']);
      expect(document.profile.role, profile['role']);
      expect(document.profile.email, profile['email']);
      expect(document.profile.displayName.primary, displayName['primary']);
      expect(document.profile.displayName.accent, displayName['accent']);
      expect(
        document.profile.displayName.navigation,
        displayName['navigation'],
      );
      expect(
        document.profile.displayName.accessible,
        displayName['accessible'],
      );
      final site = manifest['site']! as Map<String, dynamic>;
      expect(document.site.url.toString(), site['url']);
      expect(document.site.title, contains(document.profile.role));
      expect(document.site.engineeringLinks, hasLength(3));
      final analytics = site['analytics']! as Map<String, dynamic>;
      expect(
        document.site.analytics?.scriptUrl.toString(),
        analytics['script_url'],
      );
      expect(document.experience, hasLength(6));
      expect(document.currentExperience, hasLength(2));
      expect(document.mergedContributions, hasLength(5));
      expect(document.contributionsUnderReview, hasLength(3));
      expect(document.featuredContribution, isNotNull);
      expect(document.systems, hasLength(8));
      expect(document.featuredSystems, hasLength(3));
      expect(
        document.featuredSystems.every(
          (system) =>
              system.challenge.isNotEmpty &&
              system.approach.isNotEmpty &&
              system.outcome.isNotEmpty &&
              system.presentation.visual.labels.length >= 3 &&
              system.evidence.isNotEmpty &&
              system.evidence.every((entry) => entry.url.scheme == 'https'),
        ),
        isTrue,
      );
      expect(
        document.supportingSystems.every(
          (system) =>
              system.artifact.asset.startsWith('assets/work/') &&
              system.presentation.visual.kind ==
                  PortfolioSystemVisualKind.artifact &&
              system.artifact.alt.isNotEmpty &&
              system.evidence.isNotEmpty,
        ),
        isTrue,
      );
      expect(document.activeSections, [
        'home',
        'experience',
        'proof',
        'projects',
        'about',
      ]);
      expect(
        document.sources.every((source) => source.url.scheme == 'https'),
        isTrue,
      );
      expect(
        () => document.systems.add(document.systems.first),
        throwsUnsupportedError,
      );
    });

    test('keeps the content contract reusable across professional roles', () {
      final json = _manifest();
      final profile = json['profile']! as Map<String, dynamic>;
      final site = json['site']! as Map<String, dynamic>;
      profile['name'] = 'Canonical Person Record';
      profile['display_name'] = <String, dynamic>{
        'primary': 'CONFIGURED PRIMARY',
        'accent': 'Not-A-Surname',
        'navigation': 'Configured Navigation',
        'accessible': 'Accessible Configured Name',
      };
      profile['role'] = 'Product Engineer';
      site['title'] = 'Canonical Person Record — Product Engineer';
      site.remove('analytics');

      final document = PortfolioDocument.fromJson(json);
      expect(document.profile.name, 'Canonical Person Record');
      expect(document.profile.role, 'Product Engineer');
      expect(document.profile.displayName.primary, 'CONFIGURED PRIMARY');
      expect(document.profile.displayName.accent, 'Not-A-Surname');
      expect(document.profile.displayName.navigation, 'Configured Navigation');
      expect(
        document.profile.displayName.accessible,
        'Accessible Configured Name',
      );
      expect(document.site.analytics, isNull);
    });

    test('binds supporting records to real local artifacts', () async {
      final document = PortfolioDocument.fromJson(_manifest());

      for (final system in document.supportingSystems) {
        final artifact = system.artifact;
        final file = File(artifact.asset);
        expect(file.existsSync(), isTrue, reason: system.id);

        final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, artifact.width, reason: system.id);
        expect(frame.image.height, artifact.height, reason: system.id);
        frame.image.dispose();
        codec.dispose();
      }
    });

    test('supports optional experience, contribution, and work chapters', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];
      json['systems'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'about']);
    });

    test(
      'selects the featured contribution from external content metadata',
      () {
        final json = _manifest();
        final contributions = json['contributions']! as List<dynamic>;
        for (final contribution in contributions.cast<Map<String, dynamic>>()) {
          contribution['featured'] = false;
        }
        final selected = contributions.first as Map<String, dynamic>;
        selected['featured'] = true;

        final document = PortfolioDocument.fromJson(json);
        expect(document.featuredContribution?.id, selected['id']);
      },
    );

    test('preserves active chapter order without optional records', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'projects', 'about']);
    });

    test('rejects unsupported schemas and duplicate content ids', () {
      final unsupported = _manifest()..['schema_version'] = 4;
      expect(
        () => PortfolioDocument.fromJson(unsupported),
        throwsA(isA<FormatException>()),
      );

      final duplicate = _manifest();
      final contributions = duplicate['contributions']! as List<dynamic>;
      contributions.add(
        Map<String, dynamic>.from(contributions.first! as Map<String, dynamic>),
      );
      expect(
        () => PortfolioDocument.fromJson(duplicate),
        throwsA(isA<FormatException>()),
      );

      final duplicateLink = _manifest();
      final profile = duplicateLink['profile']! as Map<String, dynamic>;
      final links = profile['links']! as List<dynamic>;
      links.add(Map<String, dynamic>.from(links.first as Map<String, dynamic>));
      expect(
        () => PortfolioDocument.fromJson(duplicateLink),
        throwsA(isA<FormatException>()),
      );

      final duplicateEngineeringLink = _manifest();
      final duplicateEngineeringSite =
          duplicateEngineeringLink['site']! as Map<String, dynamic>;
      final engineeringLinks =
          duplicateEngineeringSite['engineering_links']! as List<dynamic>;
      engineeringLinks.add(
        Map<String, dynamic>.from(
          engineeringLinks.first as Map<String, dynamic>,
        ),
      );
      expect(
        () => PortfolioDocument.fromJson(duplicateEngineeringLink),
        throwsA(isA<FormatException>()),
      );

      final multipleFeatured = _manifest();
      final featuredContributions =
          multipleFeatured['contributions']! as List<dynamic>;
      (featuredContributions.first as Map<String, dynamic>)['featured'] = true;
      expect(
        () => PortfolioDocument.fromJson(multipleFeatured),
        throwsA(isA<FormatException>()),
      );

      final invalidImage = _manifest();
      final site = invalidImage['site']! as Map<String, dynamic>;
      site['social_image'] = 'https://example.com/preview.png';
      expect(
        () => PortfolioDocument.fromJson(invalidImage),
        throwsA(isA<FormatException>()),
      );

      final mismatchedIdentity = _manifest();
      final mismatchedSite =
          mismatchedIdentity['site']! as Map<String, dynamic>;
      mismatchedSite['title'] = 'Anonymous Portfolio';
      expect(
        () => PortfolioDocument.fromJson(mismatchedIdentity),
        throwsA(isA<FormatException>()),
      );

      final missingDisplayName = _manifest();
      (missingDisplayName['profile']! as Map<String, dynamic>).remove(
        'display_name',
      );
      expect(
        () => PortfolioDocument.fromJson(missingDisplayName),
        throwsA(isA<FormatException>()),
      );

      final incompleteCaseStudy = _manifest();
      final systems = incompleteCaseStudy['systems']! as List<dynamic>;
      (systems.first as Map<String, dynamic>).remove('challenge');
      expect(
        () => PortfolioDocument.fromJson(incompleteCaseStudy),
        throwsA(isA<FormatException>()),
      );

      final invalidProjectColour = _manifest();
      final invalidColourSystems =
          invalidProjectColour['systems']! as List<dynamic>;
      final invalidPresentation =
          (invalidColourSystems.first as Map<String, dynamic>)['presentation']!
              as Map<String, dynamic>;
      invalidPresentation['background'] = 'blue';
      expect(
        () => PortfolioDocument.fromJson(invalidProjectColour),
        throwsA(isA<FormatException>()),
      );

      final underspecifiedVisual = _manifest();
      final underspecifiedSystems =
          underspecifiedVisual['systems']! as List<dynamic>;
      final visual =
          ((underspecifiedSystems.first
                      as Map<String, dynamic>)['presentation']!
                  as Map<String, dynamic>)['visual']!
              as Map<String, dynamic>;
      visual['labels'] = <dynamic>['Only one'];
      expect(
        () => PortfolioDocument.fromJson(underspecifiedVisual),
        throwsA(isA<FormatException>()),
      );

      final missingEvidence = _manifest();
      final systemsWithoutEvidence =
          missingEvidence['systems']! as List<dynamic>;
      final featuredWithoutEvidence =
          systemsWithoutEvidence.first as Map<String, dynamic>;
      featuredWithoutEvidence['evidence'] = <dynamic>[];
      expect(
        () => PortfolioDocument.fromJson(missingEvidence),
        throwsA(isA<FormatException>()),
      );

      final supportingWithoutArtifact = _manifest();
      final supportingSystems =
          supportingWithoutArtifact['systems']! as List<dynamic>;
      supportingSystems
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false)
          .remove('artifact');
      expect(
        () => PortfolioDocument.fromJson(supportingWithoutArtifact),
        throwsA(isA<FormatException>()),
      );

      final featuredWithSupportingArtifact = _manifest();
      final mixedSystems =
          featuredWithSupportingArtifact['systems']! as List<dynamic>;
      final featuredSystem = mixedSystems
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == true);
      final supportingSystem = mixedSystems
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      featuredSystem['artifact'] = Map<String, dynamic>.from(
        supportingSystem['artifact']! as Map<String, dynamic>,
      );
      expect(
        () => PortfolioDocument.fromJson(featuredWithSupportingArtifact),
        throwsA(isA<FormatException>()),
      );

      final invalidArtifactPath = _manifest();
      final systemsWithInvalidArtifact =
          invalidArtifactPath['systems']! as List<dynamic>;
      final invalidArtifactSystem = systemsWithInvalidArtifact
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      final invalidArtifact =
          invalidArtifactSystem['artifact']! as Map<String, dynamic>;
      invalidArtifact['asset'] = '../generated/fake.png';
      expect(
        () => PortfolioDocument.fromJson(invalidArtifactPath),
        throwsA(isA<FormatException>()),
      );

      final missingSupportingEvidence = _manifest();
      final systemsWithoutSupportingEvidence =
          missingSupportingEvidence['systems']! as List<dynamic>;
      systemsWithoutSupportingEvidence.cast<Map<String, dynamic>>().firstWhere(
        (system) => system['featured'] == false,
      )['evidence'] = <dynamic>[];
      expect(
        () => PortfolioDocument.fromJson(missingSupportingEvidence),
        throwsA(isA<FormatException>()),
      );

      final invalidArtifactDimensions = _manifest();
      final systemsWithInvalidDimensions =
          invalidArtifactDimensions['systems']! as List<dynamic>;
      final invalidDimensionsSystem = systemsWithInvalidDimensions
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      final invalidDimensionsArtifact =
          invalidDimensionsSystem['artifact']! as Map<String, dynamic>;
      invalidDimensionsArtifact['width'] = 0;
      expect(
        () => PortfolioDocument.fromJson(invalidArtifactDimensions),
        throwsA(isA<FormatException>()),
      );

      final unsupportedArtifactFit = _manifest();
      final systemsWithUnsupportedFit =
          unsupportedArtifactFit['systems']! as List<dynamic>;
      final unsupportedFitSystem = systemsWithUnsupportedFit
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      final unsupportedFitArtifact =
          unsupportedFitSystem['artifact']! as Map<String, dynamic>;
      unsupportedFitArtifact['fit'] = 'parallax';
      expect(
        () => PortfolioDocument.fromJson(unsupportedArtifactFit),
        throwsA(isA<FormatException>()),
      );

      final unsupportedComposition = _manifest();
      final systemsWithUnsupportedComposition =
          unsupportedComposition['systems']! as List<dynamic>;
      final unsupportedCompositionSystem = systemsWithUnsupportedComposition
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      final unsupportedCompositionArtifact =
          unsupportedCompositionSystem['artifact']! as Map<String, dynamic>;
      unsupportedCompositionArtifact['composition'] = 'project_card';
      expect(
        () => PortfolioDocument.fromJson(unsupportedComposition),
        throwsA(isA<FormatException>()),
      );

      final mismatchedComposition = _manifest();
      final systemsWithMismatchedComposition =
          mismatchedComposition['systems']! as List<dynamic>;
      final mismatchedCompositionSystem = systemsWithMismatchedComposition
          .cast<Map<String, dynamic>>()
          .firstWhere((system) => system['featured'] == false);
      final mismatchedCompositionArtifact =
          mismatchedCompositionSystem['artifact']! as Map<String, dynamic>;
      mismatchedCompositionArtifact['composition'] = 'evidence_stack';
      expect(
        () => PortfolioDocument.fromJson(mismatchedComposition),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _manifest() =>
    jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;
