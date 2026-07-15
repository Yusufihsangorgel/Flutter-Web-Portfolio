import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main() {
  group('PortfolioDocument', () {
    test('loads the verified canonical content manifest', () {
      final document = PortfolioDocument.fromJson(_manifest());

      expect(document.schemaVersion, 1);
      expect(document.contentVersion, '2026.07.15.2');
      expect(document.profile.role, 'Software Engineer');
      expect(document.site.url.toString(), 'https://developeryusuf.com');
      expect(document.site.title, contains(document.profile.role));
      expect(document.experience, hasLength(4));
      expect(document.mergedContributions, hasLength(4));
      expect(document.contributionsUnderReview, hasLength(1));
      expect(document.systems, hasLength(5));
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

    test('rejects role inflation in public content', () {
      final json = _manifest();
      final profile = json['profile']! as Map<String, dynamic>;
      profile['role'] = ['Sen', 'ior Software Engineer'].join();

      expect(
        () => PortfolioDocument.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported schemas and duplicate evidence ids', () {
      final unsupported = _manifest()..['schema_version'] = 2;
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
    });
  });
}

Map<String, dynamic> _manifest() =>
    jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;
