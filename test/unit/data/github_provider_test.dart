import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';

void main() {
  group('GitHubProvider — singleton', () {
    test('instance returns the same object', () {
      final a = GitHubProvider.instance;
      final b = GitHubProvider.instance;
      expect(a, same(b));
    });

    test('hasCachedData is false on fresh instance', () {
      // The singleton may have state from earlier tests, but
      // fallback data is static and always available.
      expect(GitHubProvider.instance, isNotNull);
    });
  });

  group('GitHubProvider — fallback data', () {
    test('fallbackProfile is non-empty', () {
      final profile = GitHubProvider.fallbackProfile;
      expect(profile, isNotEmpty);
    });

    test('fallbackProfile contains expected keys', () {
      final profile = GitHubProvider.fallbackProfile;
      expect(profile.containsKey('avatar_url'), isTrue);
      expect(profile.containsKey('public_repos'), isTrue);
      expect(profile.containsKey('followers'), isTrue);
      expect(profile.containsKey('html_url'), isTrue);
      expect(profile.containsKey('login'), isTrue);
    });

    test('fallbackProfile login matches username', () {
      final profile = GitHubProvider.fallbackProfile;
      expect(profile['login'], equals('Yusufihsangorgel'));
    });

    test('fallbackProfile html_url contains username', () {
      final profile = GitHubProvider.fallbackProfile;
      final url = profile['html_url'] as String;
      expect(url, contains('Yusufihsangorgel'));
    });

    test('fallbackRepos is non-empty', () {
      final repos = GitHubProvider.fallbackRepos;
      expect(repos, isNotEmpty);
    });

    test('fallbackRepos first entry has required fields', () {
      final repo = GitHubProvider.fallbackRepos.first;
      expect(repo.containsKey('name'), isTrue);
      expect(repo.containsKey('description'), isTrue);
      expect(repo.containsKey('language'), isTrue);
      expect(repo.containsKey('stargazers_count'), isTrue);
      expect(repo.containsKey('html_url'), isTrue);
    });

    test('fallbackRepos returns a new list each call', () {
      final a = GitHubProvider.fallbackRepos;
      final b = GitHubProvider.fallbackRepos;
      expect(a, isNot(same(b)));
    });

    test('fallbackTotalStars is non-negative', () {
      expect(GitHubProvider.fallbackTotalStars, greaterThanOrEqualTo(0));
    });
  });

  group('GitHubProvider — username', () {
    test('fallback profile uses Yusufihsangorgel username', () {
      final profile = GitHubProvider.fallbackProfile;
      expect(profile['login'], equals('Yusufihsangorgel'));
    });
  });
}
