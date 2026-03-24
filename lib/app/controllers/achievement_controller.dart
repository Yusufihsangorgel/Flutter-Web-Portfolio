import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/domain/providers/i_local_storage_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Achievement definitions
// ─────────────────────────────────────────────────────────────────────────────

/// Every achievement the visitor can earn while exploring the portfolio.
enum Achievement {
  explorer(
    id: 'explorer',
    name: 'Explorer',
    description: 'Scrolled to every section',
    hint: 'Visit every part of the portfolio',
    icon: 0xe1b1, // Icons.explore_rounded
    maxProgress: 1,
  ),
  nightOwl(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Visited after midnight',
    hint: 'Come back when the moon is high',
    icon: 0xf06e2, // Icons.dark_mode_rounded
    maxProgress: 1,
  ),
  earlyBird(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Visited before 7 AM',
    hint: 'The early bird catches the worm',
    icon: 0xf0510, // Icons.wb_sunny_rounded
    maxProgress: 1,
  ),
  curiousMind(
    id: 'curious_mind',
    name: 'Curious Mind',
    description: 'Viewed all projects',
    hint: 'Take a closer look at every project',
    icon: 0xe4a2, // Icons.psychology_rounded
    maxProgress: 1,
  ),
  speedReader(
    id: 'speed_reader',
    name: 'Speed Reader',
    description: 'Scrolled through the entire page in under 30s',
    hint: 'Gotta go fast!',
    icon: 0xf06bc, // Icons.speed_rounded
    maxProgress: 1,
  ),
  deepDiver(
    id: 'deep_diver',
    name: 'Deep Diver',
    description: 'Spent over 5 minutes on a single section',
    hint: 'Take your time and soak it all in',
    icon: 0xf0580, // Icons.scuba_diving_rounded
    maxProgress: 300, // seconds
  ),
  polyglot(
    id: 'polyglot',
    name: 'Polyglot',
    description: 'Changed language at least 3 times',
    hint: 'Try speaking a few different languages',
    icon: 0xe68d, // Icons.translate_rounded
    maxProgress: 3,
  ),
  themeSwitcher(
    id: 'theme_switcher',
    name: 'Theme Switcher',
    description: 'Toggled theme 5 times',
    hint: 'Can\'t decide between light and dark?',
    icon: 0xe3ab, // Icons.palette_rounded
    maxProgress: 5,
  ),
  secretAgent(
    id: 'secret_agent',
    name: 'Secret Agent',
    description: 'Found the Konami code Easter egg',
    hint: 'Up up down down...',
    icon: 0xf0027, // Icons.policy_rounded
    maxProgress: 1,
  ),
  stalker(
    id: 'stalker',
    name: 'Stalker',
    description: 'Visited 10+ times',
    hint: 'Keep coming back for more',
    icon: 0xe6c7, // Icons.visibility_rounded
    maxProgress: 10,
  ),
  firstContact(
    id: 'first_contact',
    name: 'First Contact',
    description: 'Submitted the contact form',
    hint: 'Say hello!',
    icon: 0xe3e0, // Icons.send_rounded
    maxProgress: 1,
  ),
  soundMaster(
    id: 'sound_master',
    name: 'Sound Master',
    description: 'Toggled sound on',
    hint: 'Turn up the volume',
    icon: 0xe6ac, // Icons.volume_up_rounded
    maxProgress: 1,
  ),
  timeTraveler(
    id: 'time_traveler',
    name: 'Time Traveler',
    description: 'Used the command palette',
    hint: 'There\'s a shortcut for everything',
    icon: 0xe6b8, // Icons.watch_later_rounded
    maxProgress: 1,
  ),
  completionist(
    id: 'completionist',
    name: 'Completionist',
    description: 'Unlocked all other achievements',
    hint: 'Gotta catch \'em all',
    icon: 0xe559, // Icons.emoji_events_rounded
    maxProgress: 1,
  );

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    required this.icon,
    required this.maxProgress,
  });

  final String id;
  final String name;
  final String description;
  final String hint;

  /// Code point for the Material icon (used to reconstruct IconData).
  final int icon;

  /// Progress value at which the achievement unlocks (1 = binary unlock).
  final int maxProgress;

  /// Every achievement except [completionist].
  static List<Achievement> get allExceptCompletionist =>
      values.where((a) => a != completionist).toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

/// Manages achievement tracking, progress, persistence, and unlock callbacks.
///
/// Drop-in GetX controller — register it in your bindings and call the
/// various `record*` methods from wherever the triggering action happens.
class AchievementController extends GetxController {
  static const _storageKeyUnlocked = 'achievements_unlocked';
  static const _storageKeyProgress = 'achievements_progress';
  static const _storageKeyVisits = 'achievement_visit_count';

  // ── Observable state ─────────────────────────────────────────────────────

  /// Set of achievement IDs that have been unlocked.
  final RxSet<String> unlockedIds = <String>{}.obs;

  /// Current progress toward each achievement (id -> progress).
  final RxMap<String, int> progress = <String, int>{}.obs;

  /// Total number of achievements.
  int get totalAchievements => Achievement.values.length;

  /// Number of unlocked achievements.
  int get unlockedCount => unlockedIds.length;

  /// Callback invoked when an achievement is newly unlocked.
  /// Signature: `void Function(Achievement achievement)`.
  void Function(Achievement achievement)? onAchievementUnlocked;

  // ── Internal tracking ────────────────────────────────────────────────────

  final _sectionVisitTimestamps = <String, DateTime>{};
  Timer? _deepDiverTimer;
  DateTime? _firstScrollTimestamp;
  bool _hasReachedBottom = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
    _checkTimeBasedAchievements();
    _recordVisit();
    _startDeepDiverTracking();
  }

  @override
  void onClose() {
    _deepDiverTimer?.cancel();
    super.onClose();
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  void _loadFromStorage() {
    try {
      if (!Get.isRegistered<ILocalStorageProvider>()) return;
      final storage = Get.find<ILocalStorageProvider>();
      if (!storage.isInitialized) return;

      // Unlocked set
      final raw = storage.getString(_storageKeyUnlocked);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List).cast<String>();
        unlockedIds.addAll(list);
      }

      // Progress map
      final rawProgress = storage.getString(_storageKeyProgress);
      if (rawProgress != null && rawProgress.isNotEmpty) {
        final map = (jsonDecode(rawProgress) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as int));
        progress.addAll(map);
      }
    } catch (e) {
      dev.log('Failed to load achievements', name: 'AchievementController', error: e);
    }
  }

  void _persistState() {
    try {
      if (!Get.isRegistered<ILocalStorageProvider>()) return;
      final storage = Get.find<ILocalStorageProvider>();
      if (!storage.isInitialized) return;

      storage
        ..setString(
          _storageKeyUnlocked,
          jsonEncode(unlockedIds.toList()),
        )
        ..setString(
          _storageKeyProgress,
          jsonEncode(progress),
        );
    } catch (e) {
      dev.log('Failed to persist achievements', name: 'AchievementController', error: e);
    }
  }

  // ── Core unlock logic ────────────────────────────────────────────────────

  /// Increments progress for [achievement] by [amount].
  /// Automatically unlocks when progress reaches [Achievement.maxProgress].
  void _incrementProgress(Achievement achievement, [int amount = 1]) {
    if (unlockedIds.contains(achievement.id)) return;

    final current = progress[achievement.id] ?? 0;
    final next = (current + amount).clamp(0, achievement.maxProgress);
    progress[achievement.id] = next;

    if (next >= achievement.maxProgress) {
      _unlock(achievement);
    } else {
      _persistState();
    }
  }

  void _unlock(Achievement achievement) {
    if (unlockedIds.contains(achievement.id)) return;

    unlockedIds.add(achievement.id);
    progress[achievement.id] = achievement.maxProgress;
    _persistState();

    dev.log(
      'Achievement unlocked: ${achievement.name}',
      name: 'AchievementController',
    );

    onAchievementUnlocked?.call(achievement);

    // Check completionist after every unlock
    if (achievement != Achievement.completionist) {
      _checkCompletionist();
    }
  }

  /// Whether [achievement] has been unlocked.
  bool isUnlocked(Achievement achievement) =>
      unlockedIds.contains(achievement.id);

  /// Current progress fraction for [achievement], from 0.0 to 1.0.
  double progressFraction(Achievement achievement) {
    if (isUnlocked(achievement)) return 1.0;
    final current = progress[achievement.id] ?? 0;
    return (current / achievement.maxProgress).clamp(0.0, 1.0);
  }

  // ── Automatic checks ────────────────────────────────────────────────────

  void _checkTimeBasedAchievements() {
    final hour = DateTime.now().hour;

    // Night Owl: midnight to 4 AM
    if (hour >= 0 && hour < 4) {
      _unlock(Achievement.nightOwl);
    }

    // Early Bird: 4 AM to 7 AM
    if (hour >= 4 && hour < 7) {
      _unlock(Achievement.earlyBird);
    }
  }

  void _recordVisit() {
    try {
      if (!Get.isRegistered<ILocalStorageProvider>()) return;
      final storage = Get.find<ILocalStorageProvider>();
      if (!storage.isInitialized) return;

      final visits = (storage.getInt(_storageKeyVisits) ?? 0) + 1;
      storage.setInt(_storageKeyVisits, visits);

      progress[Achievement.stalker.id] = visits.clamp(0, Achievement.stalker.maxProgress);
      if (visits >= Achievement.stalker.maxProgress) {
        _unlock(Achievement.stalker);
      } else {
        _persistState();
      }
    } catch (e) {
      dev.log('Failed to record visit', name: 'AchievementController', error: e);
    }
  }

  void _startDeepDiverTracking() {
    _deepDiverTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isUnlocked(Achievement.deepDiver)) {
        _deepDiverTimer?.cancel();
        return;
      }

      for (final entry in _sectionVisitTimestamps.entries) {
        final elapsed = DateTime.now().difference(entry.value).inSeconds;
        if (elapsed >= Achievement.deepDiver.maxProgress) {
          _unlock(Achievement.deepDiver);
          _deepDiverTimer?.cancel();
          return;
        }
      }

      // Update progress to longest section time
      if (_sectionVisitTimestamps.isNotEmpty) {
        final maxElapsed = _sectionVisitTimestamps.values
            .map((t) => DateTime.now().difference(t).inSeconds)
            .reduce((a, b) => a > b ? a : b);
        progress[Achievement.deepDiver.id] =
            maxElapsed.clamp(0, Achievement.deepDiver.maxProgress);
      }
    });
  }

  void _checkCompletionist() {
    final allOthers = Achievement.allExceptCompletionist;
    final allUnlocked = allOthers.every((a) => unlockedIds.contains(a.id));
    if (allUnlocked) {
      _unlock(Achievement.completionist);
    }
  }

  // ── Public recording methods ─────────────────────────────────────────────
  // Call these from the appropriate places in your app.

  /// Record that a section has been scrolled into view.
  void recordSectionVisit(String sectionId) {
    // Track timestamp for deep diver
    // ignore: unnecessary_lambdas — DateTime.now() must be lazily evaluated
    _sectionVisitTimestamps.putIfAbsent(sectionId, () => DateTime.now());

    // Track first scroll time for speed reader
    _firstScrollTimestamp ??= DateTime.now();
  }

  /// Record that the visitor has scrolled to the very bottom.
  /// Call this when the last section becomes visible.
  void recordReachedBottom() {
    if (_hasReachedBottom) return;
    _hasReachedBottom = true;

    // Explorer: visited every section — caller should ensure all sections
    // have been reported via recordSectionVisit before calling this.
    _unlock(Achievement.explorer);

    // Speed Reader: reached bottom within 30 seconds of first scroll
    if (_firstScrollTimestamp != null) {
      final elapsed = DateTime.now().difference(_firstScrollTimestamp!);
      if (elapsed.inSeconds < 30) {
        _unlock(Achievement.speedReader);
      }
    }
  }

  /// Record that a project detail has been viewed.
  void recordProjectViewed(String projectId, {required int totalProjects}) {
    // We track viewed projects in a simple set persisted as progress count.
    // For simplicity, each unique project increments progress by 1.
    // The caller must provide the total project count so we know the target.
    if (isUnlocked(Achievement.curiousMind)) return;

    final current = progress[Achievement.curiousMind.id] ?? 0;
    // Increment only if we haven't hit the target yet
    if (current < totalProjects) {
      progress[Achievement.curiousMind.id] = current + 1;
      if (current + 1 >= totalProjects) {
        _unlock(Achievement.curiousMind);
      } else {
        _persistState();
      }
    }
  }

  /// Record a language change.
  void recordLanguageChange() {
    _incrementProgress(Achievement.polyglot);
  }

  /// Record a theme toggle.
  void recordThemeToggle() {
    _incrementProgress(Achievement.themeSwitcher);
  }

  /// Record the Konami code Easter egg activation.
  void recordKonamiCode() {
    _unlock(Achievement.secretAgent);
  }

  /// Record the contact form submission.
  void recordContactSubmit() {
    _unlock(Achievement.firstContact);
  }

  /// Record that sound was toggled on.
  void recordSoundToggle() {
    _unlock(Achievement.soundMaster);
  }

  /// Record that the command palette was opened.
  void recordCommandPaletteUsed() {
    _unlock(Achievement.timeTraveler);
  }

  /// Resets all achievements. Useful for testing.
  @visibleForTesting
  void resetAll() {
    unlockedIds.clear();
    progress.clear();
    _sectionVisitTimestamps.clear();
    _firstScrollTimestamp = null;
    _hasReachedBottom = false;
    _persistState();
  }
}
