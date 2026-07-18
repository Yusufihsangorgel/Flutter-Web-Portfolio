import 'dart:convert';
import 'dart:io';

import 'package:flutter_web_portfolio/app/domain/models/portfolio_document.dart';

void main(List<String> arguments) {
  if (arguments.length > 1) {
    stderr.writeln('Usage: dart run tool/validate_portfolio.dart [path]');
    exitCode = 64;
    return;
  }
  final path = arguments.firstOrNull ?? 'assets/content/portfolio.json';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Portfolio document not found: $path');
    exitCode = 64;
    return;
  }

  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map<String, dynamic>) {
      throw const FormatException('The root value must be a JSON object.');
    }
    final document = PortfolioDocument.fromJson(json);
    stdout.writeln(
      'Portfolio ${document.contentVersion} is valid: '
      '${document.profile.name}, ${document.activeSections.length} sections.',
    );
  } on Object catch (error) {
    stderr.writeln('Invalid portfolio document: $error');
    exitCode = 65;
  }
}
