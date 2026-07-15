import 'dart:convert';
import 'dart:io';

import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

PortfolioDocument loadPortfolioFixture({
  void Function(Map<String, dynamic> json)? mutate,
}) {
  final json =
      jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
          as Map<String, dynamic>;
  mutate?.call(json);
  return PortfolioDocument.fromJson(json);
}
