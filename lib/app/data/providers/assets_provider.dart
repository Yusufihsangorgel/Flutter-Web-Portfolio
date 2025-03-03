import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Asset dosyalarından veri yükleme işlemleri için provider
class AssetsProvider extends GetxService {
  /// JSON formatındaki proje verilerini yükler
  Future<List<Map<String, dynamic>>> loadProjectsData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/projects.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // Hata durumunda boş liste döndür
      print('Proje verileri yüklenirken hata: $e');
      return [];
    }
  }

  /// JSON formatındaki deneyim verilerini yükler
  Future<List<Map<String, dynamic>>> loadExperiencesData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/experiences.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // Hata durumunda boş liste döndür
      print('Deneyim verileri yüklenirken hata: $e');
      return [];
    }
  }

  /// JSON formatındaki beceri verilerini yükler
  Future<List<Map<String, dynamic>>> loadSkillsData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/skills.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      // Hata durumunda boş liste döndür
      print('Beceri verileri yüklenirken hata: $e');
      return [];
    }
  }

  /// Belirli bir dil için çeviri verilerini yükler
  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/i18n/$languageCode.json',
      );
      final Map<String, dynamic> translations = json.decode(jsonString);
      return translations;
    } catch (e) {
      // Hata durumunda boş map döndür
      print('Çeviri verileri yüklenirken hata: $e');
      return {};
    }
  }
}
