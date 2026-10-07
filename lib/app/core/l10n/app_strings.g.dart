// GENERATED — do not edit. Run: npm run generate:strings
final class AppStrings {
  const AppStrings(this.translations);

  final Map<String, Object?> translations;

  String lookup(String key, {String defaultValue = ''}) {
    Object? current = translations;
    for (final part in key.split('.')) {
      if (current is! Map<String, Object?> || !current.containsKey(part)) {
        return defaultValue;
      }
      current = current[part];
    }
    return current?.toString() ?? defaultValue;
  }

  String _interpolate(
    String key,
    String fallback,
    Map<String, String> values,
  ) => lookup(key, defaultValue: fallback).replaceAllMapped(
    RegExp(r'\{([a-zA-Z_][a-zA-Z_0-9]*)\}'),
    (match) => values[match.group(1)] ?? match.group(0)!,
  );

  String get aboutSectionEmail =>
      lookup('about_section.email', defaultValue: 'Email');

  String get aboutSectionExperience => lookup(
    'about_section.experience',
    defaultValue: 'Professional work since',
  );

  String get aboutSectionLocation =>
      lookup('about_section.location', defaultValue: 'Based in');

  String get aboutSectionPracticeTitle => lookup(
    'about_section.practice_title',
    defaultValue: 'What I work across',
  );

  String get aboutSectionTitle =>
      lookup('about_section.title', defaultValue: 'About');

  String get accessibilityBackToTop =>
      lookup('accessibility.back_to_top', defaultValue: 'Back to top');

  String get accessibilityGoHome =>
      lookup('accessibility.go_home', defaultValue: 'Go to home');

  String get accessibilityLanguageChangeFailed => lookup(
    'accessibility.language_change_failed',
    defaultValue:
        'That language could not be loaded. Your current language is still active.',
  );

  String get accessibilityLanguageMenu =>
      lookup('accessibility.language_menu', defaultValue: 'Language menu');

  String get accessibilityLanguageNotSaved => lookup(
    'accessibility.language_not_saved',
    defaultValue:
        'Your language preference could not be saved. This language will remain active for this visit.',
  );

  String get accessibilityLoadFailure => lookup(
    'accessibility.load_failure',
    defaultValue: 'The portfolio could not load. Please try again.',
  );

  String get accessibilityLoadingPortfolio => lookup(
    'accessibility.loading_portfolio',
    defaultValue: 'Loading interactive portfolio',
  );

  String get accessibilityRetry =>
      lookup('accessibility.retry', defaultValue: 'Retry');

  String get accessibilitySkipToContent =>
      lookup('accessibility.skip_to_content', defaultValue: 'Skip to content');

  String get commandPaletteAction =>
      lookup('command_palette.action', defaultValue: 'Action');

  String get commandPaletteClose =>
      lookup('command_palette.close', defaultValue: 'Close command palette');

  String commandPaletteGoTo({required String section}) => _interpolate(
    'command_palette.go_to',
    'Go to {section}',
    {'section': section},
  );

  String get commandPaletteLanguage =>
      lookup('command_palette.language', defaultValue: 'Language');

  String get commandPaletteNavigate =>
      lookup('command_palette.navigate', defaultValue: 'Navigate');

  String get commandPaletteNoMatches => lookup(
    'command_palette.no_matches',
    defaultValue: 'No matching commands',
  );

  String get commandPaletteSearchHint =>
      lookup('command_palette.search_hint', defaultValue: 'Type a command...');

  String commandPaletteSwitchTo({required String language}) => _interpolate(
    'command_palette.switch_to',
    'Switch to {language}',
    {'language': language},
  );

  String get experienceSectionPresent =>
      lookup('experience_section.present', defaultValue: 'Present');

  String get experienceSectionTitle =>
      lookup('experience_section.title', defaultValue: 'Experience');

  String get footerCommandHintPrefix =>
      lookup('footer.command_hint_prefix', defaultValue: 'Press');

  String get footerCommandHintSuffix => lookup(
    'footer.command_hint_suffix',
    defaultValue: 'to open command palette',
  );

  String get footerQuickLinks =>
      lookup('footer.quick_links', defaultValue: 'Quick Links');

  String get footerVerification =>
      lookup('footer.verification', defaultValue: 'Current focus');

  String get homeSectionBasedIn =>
      lookup('home_section.based_in', defaultValue: 'Based in');

  String get homeSectionCurrently =>
      lookup('home_section.currently', defaultValue: 'Currently');

  String get homeSectionEmail =>
      lookup('home_section.email', defaultValue: 'Email me');

  String get homeSectionFocus =>
      lookup('home_section.focus', defaultValue: 'Focus');

  String get homeSectionInspectRuntime =>
      lookup('home_section.inspect_runtime', defaultValue: 'About me');

  String get homeSectionViewGithub =>
      lookup('home_section.view_github', defaultValue: 'GitHub');

  String get homeSectionViewWork =>
      lookup('home_section.view_work', defaultValue: 'Explore my work');

  String get homeSectionWorkingSince =>
      lookup('home_section.working_since', defaultValue: 'Working since');

  String get navAbout => lookup('nav.about', defaultValue: 'About');

  String get navExperience =>
      lookup('nav.experience', defaultValue: 'Experience');

  String get navHome => lookup('nav.home', defaultValue: 'Home');

  String get navPackages => lookup('nav.packages', defaultValue: 'Packages');

  String get navProjects => lookup('nav.projects', defaultValue: 'Work');

  String get navProof => lookup('nav.proof', defaultValue: 'Open Source');

  String get navWriting => lookup('nav.writing', defaultValue: 'Writing');

  String packagesSectionMaturityLevel({
    required String level,
    required String max,
  }) => _interpolate(
    'packages_section.maturity_level',
    'Maturity {level} of {max}',
    {'level': level, 'max': max},
  );

  String get packagesSectionOpenPackage =>
      lookup('packages_section.open_package', defaultValue: 'Open on pub.dev');

  String get packagesSectionPubPoints =>
      lookup('packages_section.pub_points', defaultValue: 'pub points');

  String get packagesSectionRoadmap =>
      lookup('packages_section.roadmap', defaultValue: 'roadmap');

  String get packagesSectionStatusDoing =>
      lookup('packages_section.status_doing', defaultValue: 'in progress');

  String get packagesSectionStatusDone =>
      lookup('packages_section.status_done', defaultValue: 'shipped');

  String get packagesSectionStatusNext =>
      lookup('packages_section.status_next', defaultValue: 'next');

  String get packagesSectionStatusWaiting =>
      lookup('packages_section.status_waiting', defaultValue: 'waiting');

  String packagesSectionSubtitle({
    required String count,
    required String perfect,
  }) => _interpolate(
    'packages_section.subtitle',
    '{count} packages live on pub.dev, {perfect} of them at a perfect 160/160 score. Each one ships a measured claim, runnable examples, and the roadmap it is on.',
    {'count': count, 'perfect': perfect},
  );

  String get packagesSectionTitle =>
      lookup('packages_section.title', defaultValue: 'Published Packages');

  String get projectsSectionApproach =>
      lookup('projects_section.approach', defaultValue: 'The approach');

  String get projectsSectionCaseLabel =>
      lookup('projects_section.case_label', defaultValue: 'Case');

  String get projectsSectionChallenge =>
      lookup('projects_section.challenge', defaultValue: 'The problem');

  String get projectsSectionDecision =>
      lookup('projects_section.decision', defaultValue: 'Engineering focus');

  String get projectsSectionEvidenceIndex =>
      lookup('projects_section.evidence_index', defaultValue: 'More work');

  String get projectsSectionEvidenceIntro => lookup(
    'projects_section.evidence_intro',
    defaultValue:
        'Released products and open-source projects, shown through their original interfaces and repositories.',
  );

  String get projectsSectionIndexLabel =>
      lookup('projects_section.index_label', defaultValue: 'Index');

  String get projectsSectionOpenEngineering => lookup(
    'projects_section.open_engineering',
    defaultValue: 'Open engineering',
  );

  String get projectsSectionOpenEvidence =>
      lookup('projects_section.open_evidence', defaultValue: 'View project');

  String get projectsSectionOutcome =>
      lookup('projects_section.outcome', defaultValue: 'The result');

  String get projectsSectionOwnership =>
      lookup('projects_section.ownership', defaultValue: 'What I owned');

  String get projectsSectionSelectEvidence => lookup(
    'projects_section.select_evidence',
    defaultValue: 'Choose a project',
  );

  String get projectsSectionSelectedCases =>
      lookup('projects_section.selected_cases', defaultValue: 'Case studies');

  String get projectsSectionShippedProducts => lookup(
    'projects_section.shipped_products',
    defaultValue: 'Shipped products',
  );

  String get projectsSectionSubtitle => lookup(
    'projects_section.subtitle',
    defaultValue:
        'Current professional products, shipped releases, and public engineering work.',
  );

  String get projectsSectionTitle =>
      lookup('projects_section.title', defaultValue: 'Selected Work');

  String get proofSectionAcceptedTitle =>
      lookup('proof_section.accepted_title', defaultValue: 'Accepted upstream');

  String get proofSectionChangeLabel =>
      lookup('proof_section.change_label', defaultValue: 'The patch');

  String get proofSectionEventLabLabel =>
      lookup('proof_section.event_lab_label', defaultValue: 'Event order lab');

  String get proofSectionEventLabReplay =>
      lookup('proof_section.event_lab_replay', defaultValue: 'Replay sequence');

  String get proofSectionEventLabRisk =>
      lookup('proof_section.event_lab_risk', defaultValue: 'Risk');

  String get proofSectionEventLabSequence => lookup(
    'proof_section.event_lab_sequence',
    defaultValue: 'Event sequence',
  );

  String get proofSectionEventLabStep =>
      lookup('proof_section.event_lab_step', defaultValue: 'Step');

  String get proofSectionEventLabWithPatch =>
      lookup('proof_section.event_lab_with_patch', defaultValue: 'With patch');

  String get proofSectionEventLabWithoutPatch => lookup(
    'proof_section.event_lab_without_patch',
    defaultValue: 'Without patch',
  );

  String get proofSectionFeaturedLabel => lookup(
    'proof_section.featured_label',
    defaultValue: 'Featured contribution',
  );

  String get proofSectionOpenPullRequest => lookup(
    'proof_section.open_pull_request',
    defaultValue: 'View pull request',
  );

  String get proofSectionProblemLabel =>
      lookup('proof_section.problem_label', defaultValue: 'The failure');

  String get proofSectionReviewTitle =>
      lookup('proof_section.review_title', defaultValue: 'In review');

  String get proofSectionStatusMerged =>
      lookup('proof_section.status_merged', defaultValue: 'Merged');

  String get proofSectionStatusUnderReview =>
      lookup('proof_section.status_under_review', defaultValue: 'Under review');

  String proofSectionSummary({
    required String merged,
    required String review,
  }) => _interpolate(
    'proof_section.summary',
    '{merged} changes accepted upstream; {review} more under review.',
    {'merged': merged, 'review': review},
  );

  String get proofSectionTitle =>
      lookup('proof_section.title', defaultValue: 'Open Source');

  String get writingSectionAllWriting =>
      lookup('writing_section.all_writing', defaultValue: 'All writing');

  String get writingSectionOpenArticle =>
      lookup('writing_section.open_article', defaultValue: 'Read article');

  String get writingSectionSubtitle => lookup(
    'writing_section.subtitle',
    defaultValue: 'Recent articles from every place I publish, newest first.',
  );

  String get writingSectionTitle =>
      lookup('writing_section.title', defaultValue: 'Writing');
}
