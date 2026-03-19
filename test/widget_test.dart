import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/bindings/app_bindings.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter_web_portfolio/main.dart';

void main() {
  setUp(() {
    AppBindings().dependencies();
    Get.put(LoadingController(), permanent: true);
  });

  testWidgets('Loading screen is displayed on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LoadingAnimation), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
