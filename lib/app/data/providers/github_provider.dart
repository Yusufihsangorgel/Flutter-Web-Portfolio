import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// In-memory cached GitHub API provider.
///
/// Fetches user profile and recent repos from the GitHub public API.
/// Results are cached so repeat calls do not trigger new network requests.
class GitHubProvider {
  GitHubProvider._();
  static final instance = GitHubProvider._();

  static const _username = 'Yusufihsangorgel';
  static const _baseUrl = 'https://api.github.com';

  Map<String, dynamic>? _cachedProfile;
  List<Map<String, dynamic>>? _cachedRepos;
  int? _cachedTotalStars;

  bool get hasCachedData => _cachedProfile != null;

  /// Fetches the user profile (avatar, repos count, followers, etc.).
  Future<Map<String, dynamic>> fetchProfile() async {
    if (_cachedProfile != null) return _cachedProfile!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_username'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        _cachedProfile = json.decode(response.body) as Map<String, dynamic>;
        return _cachedProfile!;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch GitHub profile', name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  /// Fetches the 5 most recently updated public repos.
  Future<List<Map<String, dynamic>>> fetchRecentRepos() async {
    if (_cachedRepos != null) return _cachedRepos!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_username/repos?sort=updated&per_page=5'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        _cachedRepos = list.cast<Map<String, dynamic>>();
        return _cachedRepos!;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch GitHub repos', name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  /// Calculates total stars across all public repos.
  Future<int> fetchTotalStars() async {
    if (_cachedTotalStars != null) return _cachedTotalStars!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$_username/repos?per_page=100'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final repos = json.decode(response.body) as List;
        var stars = 0;
        for (final repo in repos) {
          stars += ((repo as Map<String, dynamic>)['stargazers_count'] as int?) ?? 0;
        }
        _cachedTotalStars = stars;
        return stars;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch total stars', name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  /// Static fallback data used when the API is unreachable.
  static Map<String, dynamic> get fallbackProfile => {
    'avatar_url': 'https://avatars.githubusercontent.com/u/80438211',
    'public_repos': 15,
    'followers': 10,
    'html_url': 'https://github.com/$_username',
    'login': _username,
  };

  static List<Map<String, dynamic>> get fallbackRepos => [
    {
      'name': 'Flutter-Web-Portfolio',
      'description': 'Modern and responsive Flutter web portfolio application.',
      'language': 'Dart',
      'stargazers_count': 0,
      'html_url': 'https://github.com/$_username/Flutter-Web-Portfolio',
    },
  ];

  static const fallbackTotalStars = 0;
}
