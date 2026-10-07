import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';

void main() {
  group('accepted values', () {
    test('required accessors return the typed value', () {
      final json = <String, dynamic>{
        'object': {'a': 1},
        'objects': [
          {'a': 1},
        ],
        'strings': ['one', 'two'],
        'string': 'text',
        'email': 'ada@example.com',
        'colour': '#aabbcc',
        'int': 3,
        'bool': true,
        'uri': 'https://example.com/path',
      };

      expect(requiredObject(json, 'object'), {'a': 1});
      expect(requiredObjects(json, 'objects'), [
        {'a': 1},
      ]);
      expect(requiredStrings(json, 'strings'), ['one', 'two']);
      expect(requiredString(json, 'string'), 'text');
      expect(requiredEmail(json, 'email'), 'ada@example.com');
      expect(requiredHexColor(json, 'colour'), '#AABBCC');
      expect(requiredInt(json, 'int'), 3);
      expect(requiredBool(json, 'bool'), isTrue);
      expect(requiredUri(json, 'uri'), Uri.parse('https://example.com/path'));
    });

    test('optional accessors return null for a missing key', () {
      expect(optionalObject(const {}, 'object'), isNull);
      expect(optionalUri(const {}, 'uri'), isNull);
      expect(
        optionalUri(const {'uri': 'https://example.com'}, 'uri'),
        Uri.parse('https://example.com'),
      );
    });
  });

  group('rejected values keep their messages', () {
    void expectMessage(Object? Function() read, String message) => expect(
      read,
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          message,
        ),
      ),
    );

    test('objects', () {
      expectMessage(
        () => requiredObject(const {'k': 1}, 'k'),
        'Expected object at "k".',
      );
      expectMessage(
        () => optionalObject(const {'k': 'x'}, 'k'),
        'Expected object at "k".',
      );
      expectMessage(
        () => requiredObjects(const {'k': 'x'}, 'k'),
        'Expected list at "k".',
      );
      expectMessage(
        () => requiredObjects(const {
          'k': ['x'],
        }, 'k'),
        'Expected object entries at "k".',
      );
    });

    test('strings', () {
      expectMessage(
        () => requiredStrings(const {'k': 'x'}, 'k'),
        'Expected list at "k".',
      );
      expectMessage(
        () => requiredStrings(const {
          'k': ['ok', ' '],
        }, 'k'),
        'Expected non-empty strings at "k".',
      );
      expectMessage(
        () => requiredString(const {'k': ' '}, 'k'),
        'Expected non-empty string at "k".',
      );
    });

    test('formatted strings', () {
      expectMessage(
        () => requiredEmail(const {'k': 'not-an-email'}, 'k'),
        'Expected an email address at "k".',
      );
      expectMessage(
        () => requiredHexColor(const {'k': '#12345'}, 'k'),
        'Expected a six-digit hex colour at "k".',
      );
    });

    test('scalars', () {
      expectMessage(
        () => requiredInt(const {'k': '1'}, 'k'),
        'Expected integer at "k".',
      );
      expectMessage(
        () => requiredBool(const {'k': 'true'}, 'k'),
        'Expected boolean at "k".',
      );
    });

    test('urls', () {
      const message = 'Expected an absolute HTTPS URL at "k".';
      expectMessage(
        () => requiredUri(const {'k': 'http://example.com'}, 'k'),
        message,
      );
      expectMessage(
        () => requiredUri(const {'k': 'https:///path'}, 'k'),
        message,
      );
      expectMessage(
        () => optionalUri(const {'k': 'ftp://example.com'}, 'k'),
        message,
      );
      expectMessage(() => optionalUri(const {'k': ' '}, 'k'), message);
      expectMessage(() => optionalUri(const {'k': 3}, 'k'), message);
    });
  });
}
