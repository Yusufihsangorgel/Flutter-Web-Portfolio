import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/capability.dart';

PortfolioCapability parsePortfolioCapability(Map<String, dynamic> json) =>
    PortfolioCapability(
      id: requiredString(json, 'id'),
      label: requiredString(json, 'label'),
      items: requiredStrings(json, 'items'),
    );
