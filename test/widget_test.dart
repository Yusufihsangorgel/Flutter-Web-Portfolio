// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/app_bindings.dart';
import 'package:flutter_web_portfolio/app/widgets/loading_animation.dart';
import 'package:flutter_web_portfolio/main.dart';

void main() {
  setUp(() {
    // Test öncesi Get bindings'i ayarla
    AppBindings().dependencies();
    // Mock LoadingController ekle
    Get.put(LoadingController(), permanent: true);
  });

  testWidgets('Ana sayfa yükleme testi', (WidgetTester tester) async {
    // Uygulamayı oluştur
    await tester.pumpWidget(MyApp());

    // Önce yükleme ekranının görüntülendiğini doğrula
    expect(find.byType(LoadingAnimation), findsOneWidget);

    // 3 saniye bekle (yükleme ekranı geçişi için)
    await tester.pump(const Duration(seconds: 3));

    // Animasyonlar olduğu için birkaç kez çerçeve oluştur
    await tester.pumpAndSettle();

    // TODO: Yükleme sonrası görüntülenen ana sayfa bileşenlerini test et
    // Burada özel test senaryoları ve beklenen durumlar eklenebilir
  });
}
