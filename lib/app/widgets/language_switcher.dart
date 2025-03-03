import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_controller.dart';

/// Dil seçme widget'ı
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // LanguageController try-catch ile alınarak hata durumuna karşı koruma sağlıyoruz
    try {
      final languageController = Get.find<LanguageController>();

      return Obx(() {
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageController.languageInfo['flag'] ?? '🌐',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
          color: Colors.grey[900],
          onSelected: (String languageCode) {
            languageController.changeLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return languageController.supportedLanguages.keys.map((
              String languageCode,
            ) {
              final languageName = LanguageController.getLanguageName(
                languageCode,
              );
              final flag = LanguageController.getLanguageFlag(languageCode);

              return PopupMenuItem<String>(
                value: languageCode,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      languageName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            languageController.currentLanguage == languageCode
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
        );
      });
    } catch (e) {
      // Hata durumunda boş bir container döndür
      debugPrint('LanguageSwitcher hatası: $e');
      return const SizedBox.shrink();
    }
  }
}
