import 'package:flutter_web_portfolio/app/domain/providers/key_value_store.dart';

final class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore({this.error});

  final Object? error;
  String? value;

  @override
  String? readString(String key) {
    final failure = error;
    if (failure != null) throw failure;
    return value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    final failure = error;
    if (failure != null) throw failure;
    this.value = value;
  }
}
