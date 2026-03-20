import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/providers/github_provider.dart';

void main() {
  group('GitHubProvider — fallback data', () {
    test('fallbackProfile is non-empty with expected keys', () {
      final profile = GitHubProvider.fallbackProfile('testuser');
      expect(profile, isNotEmpty);
      expect(profile.containsKey('avatar_url'), isTrue);
      expect(profile.containsKey('public_repos'), isTrue);
      expect(profile.containsKey('followers'), isTrue);
      expect(profile.containsKey('html_url'), isTrue);
      expect(profile.containsKey('login'), isTrue);
    });

    test('fallbackProfile login matches provided username', () {
      final profile = GitHubProvider.fallbackProfile('myuser');
      expect(profile['login'], equals('myuser'));
    });

    test('fallbackProfile html_url contains username', () {
      final profile = GitHubProvider.fallbackProfile('somedev');
      final url = profile['html_url'] as String;
      expect(url, contains('somedev'));
    });

    test('fallbackRepos is non-empty with required fields', () {
      final repos = GitHubProvider.fallbackRepos('testuser');
      expect(repos, isNotEmpty);
      final repo = repos.first;
      expect(repo.containsKey('name'), isTrue);
      expect(repo.containsKey('description'), isTrue);
      expect(repo.containsKey('language'), isTrue);
      expect(repo.containsKey('stargazers_count'), isTrue);
      expect(repo.containsKey('html_url'), isTrue);
    });

    test('fallbackRepos URL contains username', () {
      final repos = GitHubProvider.fallbackRepos('forkuser');
      expect(repos.first['html_url'], contains('forkuser'));
    });

    test('fallbackTotalStars is non-negative', () {
      expect(GitHubProvider.fallbackTotalStars, greaterThanOrEqualTo(0));
    });
  });
}
