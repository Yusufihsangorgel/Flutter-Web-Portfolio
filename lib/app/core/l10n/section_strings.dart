import 'package:flutter_web_portfolio/app/core/l10n/app_strings.g.dart';

extension SectionStrings on AppStrings {
  String navigationLabel(String sectionId, {String? fallback}) =>
      switch (sectionId) {
        'home' => navHome,
        'about' => navAbout,
        'experience' => navExperience,
        'proof' => navProof,
        'projects' => navProjects,
        'packages' => navPackages,
        'writing' => navWriting,
        final value => fallback ?? _unknownSection(value),
      };
}

Never _unknownSection(String sectionId) =>
    throw StateError('Unknown chapter "$sectionId".');
