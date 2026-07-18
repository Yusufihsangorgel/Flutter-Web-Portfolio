import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';

import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/motion_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';

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

/// Keyboard command palette opened with Ctrl+K or Cmd+K.
///
/// Provides fuzzy search across navigation, language, and action commands.
/// Keyboard navigable with arrow keys, Enter to select, Escape to close.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  /// Shows the command palette as a modal overlay.
  static void show(BuildContext context) {
    final language = context.read<LanguageCubit>();
    url_strategy.setTransientOverlayOpen(true);
    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: language.getText(
          'command_palette.close',
          defaultValue: 'Close command palette',
        ),
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: AppDurations.medium,
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: MotionCurves.emphasizedDecelerate,
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
        pageBuilder: (_, _, _) => PopScope<void>(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) url_strategy.setTransientOverlayOpen(false);
          },
          child: const CommandPalette(),
        ),
      ).whenComplete(() => url_strategy.setTransientOverlayOpen(false)),
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
    final scrollController = context.read<AppScrollController>();
    final urlSection = url_strategy.getUrlHash();
    final sectionToPreserve = urlSection.isNotEmpty
        ? urlSection
        : scrollController.activeSection;
    final languageController = context.read<LanguageCubit>();
    final active = scrollController.sectionIds;
    final navigateCategory = languageController.getText(
      'command_palette.navigate',
      defaultValue: 'Navigate',
    );
    final languageCategory = languageController.getText(
      'command_palette.language',
      defaultValue: 'Language',
    );

    const sectionIcons = <String, IconData>{
      'home': Icons.home_rounded,
      'about': Icons.person_rounded,
      'experience': Icons.work_rounded,
      'proof': Icons.verified_rounded,
      'projects': Icons.code_rounded,
    };

    return [
      // ── Navigation ──────────────────────────────────────────────────────
      for (final section in active)
        _PaletteCommand(
          label: languageController
              .getText('command_palette.go_to', defaultValue: 'Go to {section}')
              .replaceAll(
                '{section}',
                languageController.getText(
                  'nav.$section',
                  defaultValue:
                      '${section[0].toUpperCase()}${section.substring(1)}',
                ),
              ),
          category: navigateCategory,
          icon: sectionIcons[section] ?? Icons.arrow_forward_rounded,
          onExecute: () =>
              _executeAndClose(() => scrollController.scrollToSection(section)),
        ),

      // ── Language ────────────────────────────────────────────────────────
      for (final languageCode in languageController.supportedLanguages)
        _PaletteCommand(
          label: languageController
              .getText(
                'command_palette.switch_to',
                defaultValue: 'Switch to {language}',
              )
              .replaceAll(
                '{language}',
                LanguageCubit.getLanguageName(languageCode),
              ),
          category: languageCategory,
          icon: Icons.translate_rounded,
          onExecute: () => _executeAndClose(
            () => languageController.selectLanguage(
              languageCode,
              preserveSection: sectionToPreserve,
            ),
          ),
        ),
    ];
  }

  void _executeAndClose(VoidCallback action) {
    url_strategy.setTransientOverlayOpen(false);
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
            .where(
              (cmd) =>
                  _fuzzyMatch(cmd.label.toLowerCase(), query) ||
                  _fuzzyMatch(cmd.category.toLowerCase(), query),
            )
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
          _selectedIndex =
              (_selectedIndex - 1 + _filteredCommands.length) %
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
      url_strategy.setTransientOverlayOpen(false);
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
            style: AppFonts.inter(fontSize: 15, color: AppColors.textBright),
            decoration: InputDecoration(
              hintText: context.read<LanguageCubit>().getText(
                'command_palette.search_hint',
                defaultValue: 'Type a command...',
              ),
              hintStyle: AppFonts.inter(
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            'ESC',
            style: AppFonts.jetBrainsMono(
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
          context.read<LanguageCubit>().getText(
            'command_palette.no_matches',
            defaultValue: 'No matching commands',
          ),
          style: AppFonts.inter(fontSize: 14, color: AppColors.textSecondary),
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
              style: AppFonts.jetBrainsMono(
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
            ?categoryHeader,
            AccessibleAction(
              onTap: command.onExecute,
              onHoverChanged: (hovered) {
                if (hovered) setState(() => _selectedIndex = index);
              },
              semanticLabel: command.label,
              selected: isSelected,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: AppDurations.microFast,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        command.label,
                        style: AppFonts.inter(
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
          ],
        );
      },
    );
  }
}
