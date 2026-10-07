import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/domain/models/experience.dart';

PortfolioExperience parsePortfolioExperience(Map<String, dynamic> json) =>
    PortfolioExperience((
      id: requiredString(json, 'id'),
      company: requiredString(json, 'company'),
      role: requiredString(json, 'role'),
      domain: requiredString(json, 'domain'),
      period: requiredString(json, 'period'),
      current: requiredBool(json, 'current'),
      summary: requiredString(json, 'summary'),
      evidence: requiredStrings(json, 'evidence'),
    ));
