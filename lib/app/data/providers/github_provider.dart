import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// In-memory cached GitHub API provider.
///
/// Username is passed at runtime from cvData — not hardcoded.
/// Results are cached per-username so repeat calls skip the network.
final class GitHubProvider {
  static const _baseUrl = 'https://api.github.com';

  final Map<String, Map<String, dynamic>> _profileCache = {};
  final Map<String, List<Map<String, dynamic>>> _reposCache = {};
  final Map<String, int> _starsCache = {};

  Future<Map<String, dynamic>> fetchProfile(String username) async {
    if (_profileCache.containsKey(username)) return _profileCache[username]!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: const {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _profileCache[username] =
            json.decode(response.body) as Map<String, dynamic>;
        return _profileCache[username]!;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch GitHub profile',
          name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecentRepos(String username) async {
    if (_reposCache.containsKey(username)) return _reposCache[username]!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/repos?sort=updated&per_page=5'),
        headers: const {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        _reposCache[username] = list.cast<Map<String, dynamic>>();
        return _reposCache[username]!;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch GitHub repos',
          name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  Future<int> fetchTotalStars(String username) async {
    if (_starsCache.containsKey(username)) return _starsCache[username]!;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username/repos?per_page=100'),
        headers: const {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final repos = json.decode(response.body) as List;
        var stars = 0;
        for (final repo in repos) {
          stars += ((repo as Map<String, dynamic>)['stargazers_count']
                  as int?) ??
              0;
        }
        _starsCache[username] = stars;
        return stars;
      }
      throw Exception('GitHub API returned ${response.statusCode}');
    } catch (e) {
      dev.log('Failed to fetch total stars',
          name: 'GitHubProvider', error: e);
      rethrow;
    }
  }

  /// Fallback data when the API is unreachable.
  static Map<String, dynamic> fallbackProfile(String username) => {
        'avatar_url': 'https://avatars.githubusercontent.com/u/0',
        'public_repos': 0,
        'followers': 0,
        'html_url': 'https://github.com/$username',
        'login': username,
      };

  static List<Map<String, dynamic>> fallbackRepos(String username) => [
        {
          'name': 'Flutter-Web-Portfolio',
          'description': 'Cinematic Flutter web portfolio.',
          'language': 'Dart',
          'stargazers_count': 0,
          'html_url': 'https://github.com/$username/Flutter-Web-Portfolio',
        },
      ];

  static int get fallbackTotalStars => 0;
}
