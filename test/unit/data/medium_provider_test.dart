import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/providers/medium_provider.dart';

void main() {
  group('MediumProvider', () {
    late MediumProvider provider;

    setUp(() {
      provider = MediumProvider();
    });

    test('fetchPosts returns empty list for empty username', () async {
      final posts = await provider.fetchPosts('');
      expect(posts, isEmpty);
    });

    test('fetchPosts returns empty list for empty string username', () async {
      final result = await provider.fetchPosts('');
      expect(result, isA<List<MediumPost>>());
      expect(result, isEmpty);
    });
  });

  group('MediumPost', () {
    test('constructor sets all fields', () {
      const post = MediumPost(
        title: 'Test',
        link: 'https://example.com',
        pubDate: 'Jan 1, 2026',
        description: 'A test post',
        thumbnail: 'https://example.com/img.jpg',
        categories: ['flutter', 'dart'],
      );
      expect(post.title, 'Test');
      expect(post.link, 'https://example.com');
      expect(post.pubDate, 'Jan 1, 2026');
      expect(post.description, 'A test post');
      expect(post.thumbnail, 'https://example.com/img.jpg');
      expect(post.categories, ['flutter', 'dart']);
    });

    test('constructor has default empty values', () {
      const post = MediumPost(
        title: 'T',
        link: 'L',
        pubDate: 'P',
        description: 'D',
      );
      expect(post.thumbnail, '');
      expect(post.categories, isEmpty);
    });

    test('categories defaults to empty list', () {
      const post = MediumPost(
        title: 'Title',
        link: 'Link',
        pubDate: 'Date',
        description: 'Desc',
      );
      expect(post.categories, isA<List<String>>());
      expect(post.categories, equals(const <String>[]));
    });

    test('thumbnail defaults to empty string', () {
      const post = MediumPost(
        title: 'Title',
        link: 'Link',
        pubDate: 'Date',
        description: 'Desc',
      );
      expect(post.thumbnail, isA<String>());
      expect(post.thumbnail, equals(''));
    });

    test('all required fields are stored correctly', () {
      const post = MediumPost(
        title: 'Flutter Tips',
        link: 'https://medium.com/@user/flutter-tips',
        pubDate: 'Mar 15, 2026',
        description: 'Learn about Flutter best practices',
        thumbnail: 'https://cdn.example.com/thumb.png',
        categories: ['flutter', 'mobile', 'dart', 'development'],
      );
      expect(post.title, 'Flutter Tips');
      expect(post.link, contains('medium.com'));
      expect(post.categories.length, 4);
    });
  });
}
