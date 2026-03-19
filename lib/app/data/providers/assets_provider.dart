import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AssetsProvider extends GetxService {
  Future<List<Map<String, dynamic>>> loadProjectsData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/projects.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      dev.log('Failed to load projects data', name: 'AssetsProvider', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadExperiencesData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/experiences.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      dev.log('Failed to load experiences data', name: 'AssetsProvider', error: e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadSkillsData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/skills.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      dev.log('Failed to load skills data', name: 'AssetsProvider', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/i18n/$languageCode.json');
      final Map<String, dynamic> translations = json.decode(jsonString);
      return translations;
    } catch (e) {
      dev.log('Failed to load translations for $languageCode', name: 'AssetsProvider', error: e);
      return {};
    }
  }
}
