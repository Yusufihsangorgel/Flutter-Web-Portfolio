import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';

/// A command entry that the palette can display and execute.
class _PaletteCommand {
  const _PaletteCommand({
    required this.label,
    required this.category,
    required this.icon,
    required this.onExecute,
  });

  final String label;
  final String category;
  final IconData icon;
  final VoidCallback onExecute;
}

/// Cinematic command palette overlay — opened with Ctrl+K / Cmd+K.
///
/// Provides fuzzy search across navigation, language, and action commands.
/// Keyboard navigable with arrow keys, Enter to select, Escape to close.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  /// Shows the command palette as a modal overlay.
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close command palette',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: AppDurations.medium,
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: CinematicCurves.dramaticEntrance,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (_, __, ___) => const CommandPalette(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<_PaletteCommand> _filteredCommands = [];
  late final List<_PaletteCommand> _allCommands;

  @override
  void initState() {
    super.initState();
    _allCommands = _buildCommands();
    _filteredCommands = List.of(_allCommands);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_PaletteCommand> _buildCommands() {
    final scrollController = Get.find<AppScrollController>();
    final languageController = Get.find<LanguageController>();
    final cvData = languageController.cvData;
    final personalInfo =
        cvData['personal_info'] as Map<String, dynamic>? ?? {};

    final github = personalInfo['github'] as String? ?? '';
    final linkedin = personalInfo['linkedin'] as String? ?? '';

    final active = languageController.activeSections;

    const sectionIcons = <String, IconData>{
      'home': Icons.home_rounded,
      'about': Icons.person_rounded,
      'experience': Icons.work_rounded,
      'testimonials': Icons.format_quote_rounded,
      'blog': Icons.article_rounded,
      'projects': Icons.code_rounded,
      'contact': Icons.mail_rounded,
    };

    return [
      // ── Navigation ──────────────────────────────────────────────────────
      for (final section in active)
        _PaletteCommand(
          label: 'Go to ${section[0].toUpperCase()}${section.substring(1)}',
          category: 'Navigate',
          icon: sectionIcons[section] ?? Icons.arrow_forward_rounded,
          onExecute: () => _executeAndClose(
            () => scrollController.scrollToSection(section),
          ),
        ),

      // ── Language ────────────────────────────────────────────────────────
      for (final entry in languageController.supportedLanguages.entries)
        _PaletteCommand(
          label: 'Switch to ${entry.value}',
          category: 'Language',
          icon: Icons.translate_rounded,
          onExecute: () => _executeAndClose(
            () => languageController.changeLanguage(entry.key),
          ),
        ),

      // ── Actions ─────────────────────────────────────────────────────────
      _PaletteCommand(
        label: 'Download CV',
        category: 'Action',
        icon: Icons.download_rounded,
        onExecute: () => _executeAndClose(() async {
          final origin = Uri.base.origin;
          final basePath = Uri.base.path.endsWith('/')
              ? Uri.base.path
              : '${Uri.base.path}/';
          final uri = Uri.parse('$origin${basePath}assets/data/cv.pdf');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }),
      ),
      if (github.isNotEmpty)
        _PaletteCommand(
          label: 'Open GitHub',
          category: 'Action',
          icon: Icons.open_in_new_rounded,
          onExecute: () => _executeAndClose(() async {
            final uri = Uri.parse(github);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }),
        ),
      if (linkedin.isNotEmpty)
        _PaletteCommand(
          label: 'Open LinkedIn',
          category: 'Action',
          icon: Icons.open_in_new_rounded,
          onExecute: () => _executeAndClose(() async {
            final uri = Uri.parse(linkedin);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }),
        ),
    ];
  }

  void _executeAndClose(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = List.of(_allCommands);
      } else {
        _filteredCommands = _allCommands
            .where((cmd) =>
                _fuzzyMatch(cmd.label.toLowerCase(), query) ||
                _fuzzyMatch(cmd.category.toLowerCase(), query))
            .toList();
      }
      _selectedIndex = _filteredCommands.isEmpty
          ? -1
          : _selectedIndex.clamp(0, _filteredCommands.length - 1);
    });
  }

  /// Simple fuzzy matching — all query characters appear in order.
  bool _fuzzyMatch(String text, String query) {
    var queryIndex = 0;
    for (var i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text[i] == query[queryIndex]) queryIndex++;
    }
    return queryIndex == query.length;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (_filteredCommands.isNotEmpty) {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        }
      });
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (_filteredCommands.isNotEmpty) {
          _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) %
              _filteredCommands.length;
        }
      });
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter) {
      if (_filteredCommands.isNotEmpty &&
          _selectedIndex >= 0 &&
          _selectedIndex < _filteredCommands.length) {
        _filteredCommands[_selectedIndex].onExecute();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final paletteWidth = screenWidth < 600 ? screenWidth - 32 : 520.0;

    return Align(
      alignment: const Alignment(0, -0.3),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              width: paletteWidth,
              constraints: const BoxConstraints(maxHeight: 440),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Focus(
                onKeyEvent: _handleKeyEvent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchField(),
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    Flexible(child: _buildCommandList()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textBright,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a command...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                'ESC',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCommandList() {
    if (_filteredCommands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No matching commands',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    // Group commands by category for display
    String? lastCategory;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      itemCount: _filteredCommands.length,
      itemBuilder: (context, index) {
        final command = _filteredCommands[index];
        final isSelected = index == _selectedIndex;

        // Show category header when category changes
        Widget? categoryHeader;
        if (command.category != lastCategory) {
          lastCategory = command.category;
          categoryHeader = Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              command.category.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoryHeader != null) categoryHeader,
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _selectedIndex = index),
              child: GestureDetector(
                onTap: command.onExecute,
                child: AnimatedContainer(
                  duration: AppDurations.microFast,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        command.icon,
                        size: 16,
                        color: isSelected
                            ? AppColors.heroAccent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          command.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.textBright
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.keyboard_return_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
