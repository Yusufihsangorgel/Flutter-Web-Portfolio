import 'package:flutter/material.dart';

abstract final class SectionStyle {
  static const accentBorder = Color(0x3D1E51FF);
  static const detailAccentBorder = Color(0x361E51FF);
  static const detailBorder = Color(0x2412110F);
  static const labSurface = Color(0xFF17191F);
  static const labInk = Color(0xFF101114);
  static const labRisk = Color(0xFFFF725C);
  static const labRiskText = Color(0xFFFF9B8B);
}

String sectionDateLabel(DateTime date) => [
  date.year.toString().padLeft(4, '0'),
  date.month.toString().padLeft(2, '0'),
  date.day.toString().padLeft(2, '0'),
].join('—');
