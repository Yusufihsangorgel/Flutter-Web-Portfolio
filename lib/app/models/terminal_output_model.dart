import 'package:flutter/material.dart';

/// Terminal çıktılarının türlerini belirten enum
enum TerminalOutputType { text, command, error, system }

/// Terminal çıktılarını temsil eden model sınıfı
class TerminalOutputModel {
  /// Çıktının metin içeriği
  String content;

  /// Çıktının türü (text, command, error, system)
  final TerminalOutputType type;

  /// Çıktının rengi
  final Color color;

  /// Çıktının öneki (ör. '>')
  final String prefix;

  /// Çıktının kalın yazılıp yazılmayacağı
  final bool isBold;

  /// Çıktıya tıklandığında çalıştırılacak fonksiyon
  final VoidCallback? onTap;

  /// Çıktı animasyonunun devam edip etmediği
  bool isTyping;

  /// Çıktı animasyonunun tamamlanıp tamamlanmadığı
  bool isCompleted;

  /// Animasyon için mevcut karakter indeksi
  int currentIndex;

  TerminalOutputModel({
    required this.content,
    this.type = TerminalOutputType.text,
    this.color = Colors.white,
    this.prefix = '',
    this.isBold = false,
    this.isTyping = false,
    this.isCompleted = false,
    this.currentIndex = 0,
    this.onTap,
  });
}
