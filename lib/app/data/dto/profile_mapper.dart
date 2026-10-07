import 'package:flutter_web_portfolio/app/data/dto/json_fields.dart';
import 'package:flutter_web_portfolio/app/data/dto/link_mapper.dart';
import 'package:flutter_web_portfolio/app/domain/models/profile.dart';

PortfolioProfile parsePortfolioProfile(Map<String, dynamic> json) =>
    PortfolioProfile((
      name: requiredString(json, 'name'),
      displayName: _parsePortfolioDisplayName(
        requiredObject(json, 'display_name'),
      ),
      role: requiredString(json, 'role'),
      location: requiredString(json, 'location'),
      email: requiredEmail(json, 'email'),
      since: requiredString(json, 'since'),
      headline: requiredString(json, 'headline'),
      summary: requiredString(json, 'summary'),
      background: requiredString(json, 'background'),
      focus: requiredStrings(json, 'focus'),
      links: requiredObjects(json, 'links').map(parsePortfolioLink).toList(),
    ));

PortfolioDisplayName _parsePortfolioDisplayName(Map<String, dynamic> json) =>
    PortfolioDisplayName(
      primary: requiredString(json, 'primary'),
      accent: requiredString(json, 'accent'),
      navigation: requiredString(json, 'navigation'),
      accessible: requiredString(json, 'accessible'),
    );
