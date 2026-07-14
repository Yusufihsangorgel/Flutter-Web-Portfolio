import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/features/contact/domain/contact_mailto.dart';

void main() {
  test('encodes visitor input into a local mail-client handoff', () {
    final uri = buildContactMailtoUri(
      recipient: 'team@example.com',
      senderName: 'Ada Lovelace',
      senderEmail: 'ada@example.com',
      message: 'Flutter Web & Wasm?',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'team@example.com');
    expect(
      uri.queryParameters['subject'],
      'Portfolio message from Ada Lovelace',
    );
    expect(
      uri.queryParameters['body'],
      'Name: Ada Lovelace\nReply-to: ada@example.com\n\nFlutter Web & Wasm?',
    );
  });
}
