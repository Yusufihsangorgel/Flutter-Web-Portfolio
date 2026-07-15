import 'dart:convert';
import 'dart:io';

import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

PortfolioDocument loadPortfolioFixture() => PortfolioDocument.fromJson(
  jsonDecode(File('assets/content/portfolio.json').readAsStringSync())
      as Map<String, dynamic>,
);
