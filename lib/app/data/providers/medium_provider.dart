import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

/// Fetches blog posts from any Medium profile via rss2json public API.
/// Username is passed at runtime — not hardcoded.
final class MediumProvider {
  static const _rss2jsonBase = 'https://api.rss2json.com/v1/api.json?rss_url=';

  final Map<String, List<MediumPost>> _cache = {};

  Future<List<MediumPost>> fetchPosts(String mediumUsername) async {
    if (mediumUsername.isEmpty) return [];
    if (_cache.containsKey(mediumUsername)) return _cache[mediumUsername]!;

    final feedUrl = 'https://medium.com/feed/@$mediumUsername';
    final apiUrl = '$_rss2jsonBase${Uri.encodeComponent(feedUrl)}';

    try {
      final response = await http.get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] != 'ok') return [];

        final items = data['items'] as List? ?? [];
        final posts = items.map((item) {
          final raw = item as Map<String, dynamic>;
          return MediumPost(
            title: (raw['title'] as String?) ?? '',
            link: (raw['link'] as String?) ?? '',
            pubDate: _formatDate(raw['pubDate'] as String?),
            description: _stripHtml(raw['description'] as String? ?? ''),
            thumbnail: (raw['thumbnail'] as String?) ?? '',
            categories: (raw['categories'] as List?)
                    ?.whereType<String>()
                    .take(4)
                    .toList() ??
                [],
          );
        }).toList();

        _cache[mediumUsername] = posts;
        return posts;
      }
    } catch (e) {
      dev.log('Medium fetch failed for @$mediumUsername',
          name: 'MediumProvider', error: e);
    }

    return [];
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } on FormatException catch (e) {
      dev.log('Date parse failed', name: 'MediumProvider', error: e);
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  static String _stripHtml(String html) {
    final stripped = html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
    if (stripped.length > 200) {
      return '${stripped.substring(0, 200).trimRight()}...';
    }
    return stripped;
  }
}

/// Single Medium blog post.
final class MediumPost {
  const MediumPost({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.description,
    this.thumbnail = '',
    this.categories = const [],
  });

  final String title;
  final String link;
  final String pubDate;
  final String description;
  final String thumbnail;
  final List<String> categories;
}
