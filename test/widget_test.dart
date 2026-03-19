import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/main.dart';

void main() {
  test('LoadingController manages loading state', () {
    final controller = LoadingController();
    expect(controller.isLoading, isTrue);

    controller.setLoading(false);
    expect(controller.isLoading, isFalse);

    controller.setLoading(true);
    expect(controller.isLoading, isTrue);
  });
}
