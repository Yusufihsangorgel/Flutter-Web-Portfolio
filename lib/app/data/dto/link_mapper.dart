import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/shared_value_types.dart';

PortfolioLink parsePortfolioLink(Map<String, dynamic> json) => PortfolioLink(
  id: requiredString(json, 'id'),
  label: requiredString(json, 'label'),
  url: requiredUri(json, 'url'),
);
