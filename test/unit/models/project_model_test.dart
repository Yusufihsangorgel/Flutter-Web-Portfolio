import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/models/project_model.dart';

void main() {
  group('ProjectModel', () {
    group('fromJson', () {
      test('parses all required fields', () {
        final json = {
          'id': '1',
          'title': 'Test Project',
          'description': 'A test project',
          'technologies': ['Flutter', 'Dart'],
          'imageUrl': 'https://example.com/image.png',
          'liveUrl': 'https://example.com',
          'githubUrl': 'https://github.com/test',
        };

        final model = ProjectModel.fromJson(json);

        expect(model.id, '1');
        expect(model.title, 'Test Project');
        expect(model.description, 'A test project');
        expect(model.technologies, ['Flutter', 'Dart']);
        expect(model.imageUrl, 'https://example.com/image.png');
        expect(model.liveUrl, 'https://example.com');
        expect(model.githubUrl, 'https://github.com/test');
      });

      test('defaults optional fields to empty string', () {
        final json = {
          'id': '1',
          'title': 'Test',
          'description': 'Desc',
          'technologies': ['Dart'],
          'imageUrl': 'img.png',
        };

        final model = ProjectModel.fromJson(json);

        expect(model.liveUrl, '');
        expect(model.githubUrl, '');
      });

      test('handles missing fields gracefully', () {
        final model = ProjectModel.fromJson({});

        expect(model.id, '');
        expect(model.title, '');
        expect(model.technologies, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const model = ProjectModel(
          id: '1',
          title: 'Test',
          description: 'Desc',
          technologies: ['Flutter'],
          imageUrl: 'img.png',
          liveUrl: 'https://live.com',
          githubUrl: 'https://github.com',
        );

        final json = model.toJson();

        expect(json['id'], '1');
        expect(json['title'], 'Test');
        expect(json['technologies'], ['Flutter']);
        expect(json['liveUrl'], 'https://live.com');
      });
    });

    test('fromJson and toJson are symmetric', () {
      final originalJson = {
        'id': '42',
        'title': 'Round Trip',
        'description': 'Testing symmetry',
        'technologies': ['A', 'B', 'C'],
        'imageUrl': 'pic.jpg',
        'liveUrl': 'https://live.example.com',
        'githubUrl': 'https://github.com/test',
      };

      final model = ProjectModel.fromJson(originalJson);
      final roundTripped = model.toJson();

      expect(roundTripped, originalJson);
    });
  });
}
