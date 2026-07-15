import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  group('PortfolioDocument', () {
    test('loads the verified canonical content manifest', () {
      final manifest = _manifest();
      final document = PortfolioDocument.fromJson(manifest);
      final profile = manifest['profile']! as Map<String, dynamic>;
      final displayName = profile['display_name']! as Map<String, dynamic>;

      expect(document.schemaVersion, 3);
      expect(document.contentVersion, manifest['content_version']);
      expect(document.profile.name, profile['name']);
      expect(document.profile.role, profile['role']);
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
      expect(document.experience, hasLength(4));
      expect(document.mergedContributions, hasLength(4));
      expect(document.contributionsUnderReview, hasLength(2));
      expect(document.systems, hasLength(8));
      expect(document.featuredSystems, hasLength(3));
      expect(
        document.featuredSystems.every(
          (system) =>
              system.challenge != null &&
              system.approach != null &&
              system.outcome != null &&
              system.evidence.isNotEmpty &&
              system.evidence.every((entry) => entry.url.scheme == 'https'),
        ),
        isTrue,
      );
      expect(document.activeSections, [
        'home',
        'about',
        'experience',
        'proof',
        'projects',
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

    test('supports optional experience, contribution, and work chapters', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];
      json['systems'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'about']);
    });

    test('preserves active chapter order without optional records', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'about', 'projects']);
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
    });
  });
}

Map<String, dynamic> _manifest() =>
    jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;
