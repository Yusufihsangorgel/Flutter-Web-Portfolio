part of 'home_view.dart';

String _chapterLabel(BuildContext context, SectionId id) =>
    context.strings.navigationLabel(id.value);

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
