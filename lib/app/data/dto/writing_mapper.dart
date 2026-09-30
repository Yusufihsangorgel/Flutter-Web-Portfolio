import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/writing.dart';

PortfolioWritingSource parsePortfolioWritingSource(Map<String, dynamic> json) =>
    PortfolioWritingSource((
      id: requiredString(json, 'id'),
      label: requiredString(json, 'label'),
      kind: PortfolioWritingSourceKind.parse(requiredString(json, 'kind')),
      url: requiredUri(json, 'url'),
      profileUrl: requiredUri(json, 'profile_url'),
    ));

PortfolioWritingEntry parsePortfolioWritingEntry(Map<String, dynamic> json) =>
    PortfolioWritingEntry(
      title: requiredString(json, 'title'),
      url: requiredUri(json, 'url'),
      source: requiredString(json, 'source'),
      date: DateTime.parse(requiredString(json, 'date')),
    );
