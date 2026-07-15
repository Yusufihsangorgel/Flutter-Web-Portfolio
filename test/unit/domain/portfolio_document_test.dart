import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  group('PortfolioDocument', () {
    test('loads the verified canonical content manifest', () {
      final document = PortfolioDocument.fromJson(_manifest());

      expect(document.schemaVersion, 2);
      expect(document.contentVersion, '2026.07.15.5');
      expect(document.profile.name, 'Yusuf İhsan Görgel');
      expect(document.profile.role, 'Software Engineer');
      expect(document.site.url.toString(), 'https://developeryusuf.com');
      expect(document.site.title, contains(document.profile.role));
      expect(
        document.site.analytics?.scriptUrl.toString(),
        'https://analytics.developeryusuf.com/js/script.js',
      );
      expect(document.experience, hasLength(4));
      expect(document.mergedContributions, hasLength(4));
      expect(document.contributionsUnderReview, hasLength(2));
      expect(document.systems, hasLength(8));
      expect(document.featuredSystems, hasLength(3));
      expect(document.activeSections, [
        'home',
        'about',
        'experience',
        'proof',
        'projects',
      ]);
      expect(document.sectionNumber('about'), '01');
      expect(document.sectionNumber('experience'), '02');
      expect(document.sectionNumber('proof'), '03');
      expect(document.sectionNumber('projects'), '04');
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
      profile['name'] = 'Example Person';
      profile['role'] = 'Product Engineer';
      site['title'] = 'Example Person — Product Engineer';
      site.remove('analytics');

      final document = PortfolioDocument.fromJson(json);
      expect(document.profile.name, 'Example Person');
      expect(document.profile.role, 'Product Engineer');
      expect(document.site.analytics, isNull);
    });

    test('supports optional experience, contribution, and work chapters', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];
      json['systems'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'about']);
      expect(document.sectionNumber('about'), '01');
      expect(
        () => document.sectionNumber('projects'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('numbers mounted chapters without gaps', () {
      final json = _manifest();
      json['experience'] = <dynamic>[];
      json['contributions'] = <dynamic>[];

      final document = PortfolioDocument.fromJson(json);
      expect(document.activeSections, ['home', 'about', 'projects']);
      expect(document.sectionNumber('about'), '01');
      expect(document.sectionNumber('projects'), '02');
    });

    test('rejects unsupported schemas and duplicate evidence ids', () {
      final unsupported = _manifest()..['schema_version'] = 3;
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
    });
  });
}

Map<String, dynamic> _manifest() =>
    jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;
