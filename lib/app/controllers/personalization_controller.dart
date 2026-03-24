import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/services/visitor_analytics.dart';

/// Personalisation signals derived from [VisitorAnalytics].
///
/// The controller is reactive (GetX) and exposes observable properties that
/// widgets can bind to. All personalisation is subtle, privacy-respecting,
/// and entirely client-side.
class PersonalizationController extends GetxController {
  PersonalizationController({VisitorAnalytics? analytics})
      : _analytics = analytics ?? VisitorAnalytics();

  final VisitorAnalytics _analytics;

  // ─── Observables ─────────────────────────────────────────────────

  /// Personalised greeting line (e.g. "Welcome back").
  final greeting = ''.obs;

  /// Secondary intro text adjusted to visitor familiarity.
  final introText = ''.obs;

  /// Whether to show the full (expanded) intro or a condensed variant.
  final showFullIntro = true.obs;

  /// Suggested theme mode — true = dark, false = light, null = no suggestion.
  final Rxn<bool> suggestedDarkMode = Rxn<bool>();

  /// CTA button label adjusted by engagement.
  final ctaText = 'See What I Can Do'.obs;

  /// Ordered section IDs — may be re-arranged based on interests.
  final RxList<String> sectionOrder = <String>[].obs;

  /// Project IDs recommended based on previous views.
  final RxList<String> recommendedProjectIds = <String>[].obs;

  /// Time-appropriate greeting prefix (Good morning / afternoon / evening).
  final timeGreeting = ''.obs;

  /// Visitor's total visit count (for optional display).
  final visitCount = 0.obs;

  /// Current engagement level.
  final Rx<EngagementLevel> engagement = EngagementLevel.low.obs;

  /// Whether the visitor arrived from GitHub.
  final isFromGitHub = false.obs;

  // Default section ordering — matches Routes.sectionIds.
  static const _defaultOrder = [
    'home',
    'about',
    'experience',
    'testimonials',
    'blog',
    'projects',
    'contact',
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _analytics.init();
    _refresh();
  }

  @override
  void onClose() {
    _analytics.flush();
    super.onClose();
  }

  /// Re-derive all personalisation signals from the current analytics state.
  @override
  void refresh() => _refresh();

  // ─── Core logic ──────────────────────────────────────────────────

  void _refresh() {
    try {
      final profile = _analytics.profile;

      visitCount.value = profile.visitCount;
      engagement.value = profile.engagement;

      _applyGreeting(profile);
      _applyThemeSuggestion(profile);
      _applyCta(profile);
      _applySectionOrder(profile);
      _applyRecommendations(profile);
      _detectGitHub(profile);
    } catch (e) {
      dev.log('Personalisation refresh failed',
          name: 'PersonalizationController', error: e);
    }
  }

  // ─── Greeting personalisation ────────────────────────────────────

  void _applyGreeting(VisitorProfile profile) {
    // Time-appropriate prefix.
    final hour = profile.visitHour;
    if (hour >= 5 && hour < 12) {
      timeGreeting.value = 'Good morning';
    } else if (hour >= 12 && hour < 18) {
      timeGreeting.value = 'Good afternoon';
    } else {
      timeGreeting.value = 'Good evening';
    }

    // Familiarity-based greeting.
    if (profile.visitCount <= 1) {
      greeting.value = 'Welcome';
      introText.value =
          "I'm a developer who crafts polished digital experiences.";
      showFullIntro.value = true;
    } else if (profile.visitCount <= 4) {
      greeting.value = 'Welcome back';
      introText.value = 'Good to see you again.';
      showFullIntro.value = false;
    } else {
      greeting.value = 'Hey again!';
      introText.value = 'You know the way around.';
      showFullIntro.value = false;
    }
  }

  // ─── Theme suggestion ───────────────────────────────────────────

  void _applyThemeSuggestion(VisitorProfile profile) {
    final hour = profile.visitHour;
    // Suggest dark mode at night (20:00 – 06:00).
    if (hour >= 20 || hour < 6) {
      suggestedDarkMode.value = true;
    } else {
      suggestedDarkMode.value = false;
    }
  }

  // ─── CTA personalisation ────────────────────────────────────────

  void _applyCta(VisitorProfile profile) {
    ctaText.value = switch (profile.engagement) {
      EngagementLevel.high => "Let's Work Together",
      EngagementLevel.medium => 'Explore My Work',
      EngagementLevel.low => 'See What I Can Do',
    };
  }

  // ─── Content ordering ───────────────────────────────────────────

  void _applySectionOrder(VisitorProfile profile) {
    final order = List<String>.from(_defaultOrder);

    if (profile.interests.isNotEmpty) {
      final topInterest = profile.interests.first;

      // If the visitor's primary interest is a movable section, promote it
      // to just after 'home' + 'about' (we always keep those on top).
      if (topInterest != 'home' &&
          topInterest != 'about' &&
          topInterest != 'contact') {
        order.remove(topInterest);
        // Insert after 'about' (index 2 in default order).
        final insertAt = order.indexOf('about') + 1;
        order.insert(insertAt.clamp(0, order.length), topInterest);
      }
    }

    // If referrer is GitHub, promote projects.
    if (profile.referrerSource.contains('github')) {
      if (order.remove('projects')) {
        final insertAt = order.indexOf('about') + 1;
        order.insert(insertAt.clamp(0, order.length), 'projects');
      }
    }

    sectionOrder.assignAll(order);
  }

  // ─── Project recommendations ─────────────────────────────────────

  void _applyRecommendations(VisitorProfile profile) {
    // Simple collaborative-filtering stand-in: if the visitor has viewed
    // projects, recommend other projects they haven't seen yet.
    //
    // Without a full project list we can only expose viewed IDs so that
    // downstream widgets can filter. A more sophisticated implementation
    // would match technologies between viewed and unviewed projects.
    recommendedProjectIds.assignAll(profile.viewedProjectIds);
  }

  // ─── GitHub detection ────────────────────────────────────────────

  void _detectGitHub(VisitorProfile profile) {
    isFromGitHub.value = profile.referrerSource.contains('github');
  }

  // ─── Public convenience accessors ────────────────────────────────

  /// The underlying analytics service, exposed for widgets that need to
  /// record events (e.g. project clicks, section enter).
  VisitorAnalytics get analytics => _analytics;

  /// Whether the visitor is on their first-ever visit.
  bool get isFirstVisit => visitCount.value <= 1;

  /// Whether the visitor qualifies as a frequent visitor.
  bool get isFrequentVisitor => visitCount.value >= 5;
}
