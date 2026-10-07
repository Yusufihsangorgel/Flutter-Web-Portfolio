/// Typed accessors over decoded JSON objects. Every failure is a
/// [FormatException] that names the offending key.
library;

Map<String, dynamic> requiredObject(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final Map<String, dynamic> value => value,
      _ => throw FormatException('Expected object at "$key".'),
    };

Map<String, dynamic>? optionalObject(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      null => null,
      final Map<String, dynamic> value => value,
      _ => throw FormatException('Expected object at "$key".'),
    };

List<Map<String, dynamic>> requiredObjects(
  Map<String, dynamic> json,
  String key,
) => switch (json[key]) {
  final List<dynamic> value =>
    value
        .map(
          (entry) => switch (entry) {
            final Map<String, dynamic> object => object,
            _ => throw FormatException('Expected object entries at "$key".'),
          },
        )
        .toList(growable: false),
  _ => throw FormatException('Expected list at "$key".'),
};

List<String> requiredStrings(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final List<dynamic> value =>
        value
            .map(
              (entry) => switch (entry) {
                final String string when string.trim().isNotEmpty => string,
                _ => throw FormatException(
                  'Expected non-empty strings at "$key".',
                ),
              },
            )
            .toList(growable: false),
      _ => throw FormatException('Expected list at "$key".'),
    };

String requiredString(Map<String, dynamic> json, String key) =>
    switch (json[key]) {
      final String value when value.trim().isNotEmpty => value,
      _ => throw FormatException('Expected non-empty string at "$key".'),
    };

String requiredEmail(Map<String, dynamic> json, String key) {
  final value = requiredString(json, key);
  if (value.length > 254 ||
      !RegExp(
        r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?)+$',
      ).hasMatch(value)) {
    throw FormatException('Expected an email address at "$key".');
  }
  return value;
}

String requiredHexColor(Map<String, dynamic> json, String key) {
  final value = requiredString(json, key);
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
    throw FormatException('Expected a six-digit hex colour at "$key".');
  }
  return value.toUpperCase();
}

int requiredInt(Map<String, dynamic> json, String key) => switch (json[key]) {
  final int value => value,
  _ => throw FormatException('Expected integer at "$key".'),
};

bool requiredBool(Map<String, dynamic> json, String key) => switch (json[key]) {
  final bool value => value,
  _ => throw FormatException('Expected boolean at "$key".'),
};

Uri requiredUri(Map<String, dynamic> json, String key) {
  final value = Uri.parse(requiredString(json, key));
  if (value.scheme != 'https' || value.host.isEmpty) {
    throw FormatException('Expected an absolute HTTPS URL at "$key".');
  }
  return value;
}

Uri? optionalUri(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value case final String string when string.trim().isNotEmpty) {
    final uri = Uri.parse(string);
    if (uri.scheme == 'https' && uri.host.isNotEmpty) return uri;
  }
  throw FormatException('Expected an absolute HTTPS URL at "$key".');
}
