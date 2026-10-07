part of 'home_view.dart';

String _chapterLabel(BuildContext context, SectionId id) => switch (id.value) {
  'home' => context.strings.navHome,
  'about' => context.strings.navAbout,
  'experience' => context.strings.navExperience,
  'proof' => context.strings.navProof,
  'projects' => context.strings.navProjects,
  'packages' => context.strings.navPackages,
  'writing' => context.strings.navWriting,
  final value => throw StateError('Unknown chapter "$value".'),
};

Widget _widgetFor(SectionId sectionId) => switch (sectionId.value) {
  'home' => const HomeSection(),
  'about' => const AboutSection(),
  'experience' => const ExperienceSection(),
  'proof' => const ProofSection(),
  'projects' => const ProjectsSection(),
  'packages' => const PackagesSection(),
  'writing' => const WritingSection(),
  final value => throw StateError(
    'No section widget is registered for narrative chapter "$value".',
  ),
};
