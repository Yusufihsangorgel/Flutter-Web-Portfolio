import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/portfolio_document_mapper.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/portfolio.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('existing records default to a disabled resume', () {
    expect(parsePortfolioDocument(_fixture()).site.resumeEnabled, isFalse);
  });

  test('resume availability survives localization and serialization', () {
    final raw = _fixture();
    final site = raw['site']! as Map<String, dynamic>;
    site['resume_enabled'] = true;
    final document = parsePortfolioDocument(raw);
    final localized = document.site.copyWith((
      title: document.site.title,
      description: document.site.description,
      socialDescription: document.site.socialDescription,
      engineeringLinks: document.site.engineeringLinks,
    ));
    expect(localized.resumeEnabled, isTrue);
    expect(localized.toJson()['resume_enabled'], isTrue);
    final reparsed = _fixture()..['site'] = localized.toJson();
    expect(parsePortfolioDocument(reparsed).site.resumeEnabled, isTrue);
  });

  test('explicit false disables the resume', () {
    final raw = _fixture();
    (raw['site']! as Map<String, dynamic>)['resume_enabled'] = false;
    expect(parsePortfolioDocument(raw).site.resumeEnabled, isFalse);
  });

  test('resume url follows the document base when enabled', () {
    final raw = _fixture();
    final site = raw['site']! as Map<String, dynamic>;
    expect(parsePortfolioDocument(raw).site.resumeUrl, isNull);
    site['resume_enabled'] = false;
    expect(parsePortfolioDocument(raw).site.resumeUrl, isNull);
    site['resume_enabled'] = true;
    final resumeUrl = parsePortfolioDocument(raw).site.resumeUrl!;
    expect(resumeUrl.toString(), 'resume.pdf');
    _expectDocumentBaseResolution(resumeUrl);
  });

  test('malformed resume flags are rejected', () {
    for (final value in [null, 'true', 1, <String, dynamic>{}]) {
      final raw = _fixture();
      (raw['site']! as Map<String, dynamic>)['resume_enabled'] = value;
      expect(() => parsePortfolioDocument(raw), throwsFormatException);
    }
  });
}

void _expectDocumentBaseResolution(Uri resumeUrl) {
  for (final (base, location, expected) in [
    (
      'https://example.com/',
      'https://example.com/',
      'https://example.com/resume.pdf',
    ),
    (
      'https://example.com/portfolio/',
      'https://example.com/portfolio/',
      'https://example.com/portfolio/resume.pdf',
    ),
    (
      'https://example.com/portfolio/',
      'https://example.com/portfolio/deep/',
      'https://example.com/portfolio/resume.pdf',
    ),
  ]) {
    expect(Uri.parse(base).resolveUri(resumeUrl).toString(), expected);
    if (location != base) {
      expect(
        Uri.parse(location).resolveUri(resumeUrl).toString(),
        isNot(expected),
      );
    }
  }
}
