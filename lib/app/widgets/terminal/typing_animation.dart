import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';

/// Terminal yazı animasyonu yardımcısı
class TypingAnimation {
  /// Rastgele değerler için Random nesnesi
  final math.Random _random = math.Random();

  /// Terminal çıktısını yazı yazma efektiyle gösterir
  ///
  /// [output] Animasyon uygulanacak çıktı
  /// [onComplete] Animasyon tamamlandığında çalıştırılacak fonksiyon
  /// [setState] Durumu güncellemek için kullanılacak fonksiyon
  /// [baseDuration] Her karakter arasındaki temel bekleme süresi (ms)
  /// [randomVariation] Bekleme süresine eklenecek rastgele değişim (ms)
  void simulateTyping({
    required TerminalOutputModel output,
    required VoidCallback onComplete,
    required Function(VoidCallback) setState,
    int baseDuration = 8,
    int randomVariation = 5,
  }) {
    if (output.content.isEmpty) {
      setState(() {
        output.isTyping = false;
        output.isCompleted = true;
      });
      onComplete();
      return;
    }

    // Rastgele yazma hızı hesapla
    final typingDelay = baseDuration + _random.nextInt(randomVariation);

    // Bir karakteri göster ve sonraki karaktere geç
    Future.delayed(Duration(milliseconds: typingDelay), () {
      setState(() {
        output.currentIndex++;

        // Animasyon tamamlandı mı kontrol et
        if (output.currentIndex >= output.content.length) {
          output.isTyping = false;
          output.isCompleted = true;
          onComplete();
        } else {
          // Devam et
          simulateTyping(
            output: output,
            onComplete: onComplete,
            setState: setState,
            baseDuration: baseDuration,
            randomVariation: randomVariation,
          );
        }
      });
    });
  }
}
