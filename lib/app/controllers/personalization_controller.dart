import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/services/visitor_analytics.dart';

@immutable
final class PersonalizationState {
  const PersonalizationState({
    required this.greeting,
    required this.introText,
    required this.showFullIntro,
    required this.suggestedDarkMode,
    required this.ctaText,
    required this.sectionOrder,
    required this.recommendedProjectIds,
    required this.timeGreeting,
    required this.visitCount,
    required this.engagement,
    required this.isFromGitHub,
  });

  const PersonalizationState.initial()
    : greeting = '',
      introText = '',
      showFullIntro = true,
      suggestedDarkMode = null,
      ctaText = 'See What I Can Do',
      sectionOrder = const [],
      recommendedProjectIds = const [],
      timeGreeting = '',
      visitCount = 0,
      engagement = EngagementLevel.low,
      isFromGitHub = false;

  final String greeting;
  final String introText;
  final bool showFullIntro;
  final bool? suggestedDarkMode;
  final String ctaText;
  final List<String> sectionOrder;
  final List<String> recommendedProjectIds;
  final String timeGreeting;
  final int visitCount;
  final EngagementLevel engagement;
  final bool isFromGitHub;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizationState &&
          greeting == other.greeting &&
          introText == other.introText &&
          showFullIntro == other.showFullIntro &&
          suggestedDarkMode == other.suggestedDarkMode &&
          ctaText == other.ctaText &&
          listEquals(sectionOrder, other.sectionOrder) &&
          listEquals(recommendedProjectIds, other.recommendedProjectIds) &&
          timeGreeting == other.timeGreeting &&
          visitCount == other.visitCount &&
          engagement == other.engagement &&
          isFromGitHub == other.isFromGitHub;

  @override
  int get hashCode => Object.hash(
    greeting,
    introText,
    showFullIntro,
    suggestedDarkMode,
    ctaText,
    Object.hashAll(sectionOrder),
    Object.hashAll(recommendedProjectIds),
    timeGreeting,
    visitCount,
    engagement,
    isFromGitHub,
  );
}

/// Derives privacy-preserving presentation hints from local-only analytics.
final class PersonalizationController extends Cubit<PersonalizationState> {
  PersonalizationController({required VisitorAnalytics analytics})
    : _analytics = analytics,
      super(const PersonalizationState.initial()) {
    _analytics.init();
    refresh();
  }

  final VisitorAnalytics _analytics;

  static const _defaultOrder = [
    'home',
    'about',
    'experience',
    'proof',
    'blog',
    'projects',
    'contact',
  ];

  void refresh() {
    try {
      final profile = _analytics.profile;
      final timeGreeting = switch (profile.visitHour) {
        >= 5 && < 12 => 'Good morning',
        >= 12 && < 18 => 'Good afternoon',
        _ => 'Good evening',
      };

      final (greeting, introText, showFullIntro) = switch (profile.visitCount) {
        <= 1 => (
          'Welcome',
          "I'm a developer who crafts polished digital experiences.",
          true,
        ),
        <= 4 => ('Welcome back', 'Good to see you again.', false),
        _ => ('Hey again!', 'You know the way around.', false),
      };

      final ctaText = switch (profile.engagement) {
        EngagementLevel.high => "Let's Work Together",
        EngagementLevel.medium => 'Explore My Work',
        EngagementLevel.low => 'See What I Can Do',
      };

      final sectionOrder = _deriveSectionOrder(profile);
      emit(
        PersonalizationState(
          greeting: greeting,
          introText: introText,
          showFullIntro: showFullIntro,
          suggestedDarkMode: profile.visitHour >= 20 || profile.visitHour < 6,
          ctaText: ctaText,
          sectionOrder: List.unmodifiable(sectionOrder),
          recommendedProjectIds: List.unmodifiable(profile.viewedProjectIds),
          timeGreeting: timeGreeting,
          visitCount: profile.visitCount,
          engagement: profile.engagement,
          isFromGitHub: profile.referrerSource.contains('github'),
        ),
      );
    } catch (error, stackTrace) {
      dev.log(
        'Personalisation refresh failed',
        name: 'PersonalizationController',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static List<String> _deriveSectionOrder(VisitorProfile profile) {
    final order = List<String>.from(_defaultOrder);
    if (profile.interests.isNotEmpty) {
      final topInterest = profile.interests.first;
      if (topInterest != 'home' &&
          topInterest != 'about' &&
          topInterest != 'contact' &&
          order.remove(topInterest)) {
        order.insert(order.indexOf('about') + 1, topInterest);
      }
    }

    if (profile.referrerSource.contains('github') && order.remove('projects')) {
      order.insert(order.indexOf('about') + 1, 'projects');
    }
    return order;
  }

  VisitorAnalytics get analytics => _analytics;
  bool get isFirstVisit => state.visitCount <= 1;
  bool get isFrequentVisitor => state.visitCount >= 5;

  @override
  Future<void> close() {
    _analytics.flush();
    return super.close();
  }
}
