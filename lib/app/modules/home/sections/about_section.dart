import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';
import 'package:flutter_web_portfolio/app/widgets/terminal/terminal_command_handler.dart';
import 'package:flutter_web_portfolio/app/widgets/terminal/terminal_widget.dart';
import 'package:flutter_web_portfolio/app/widgets/terminal/typing_animation.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';

/// About section - provides user interaction via a terminal interface
class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection>
    with SingleTickerProviderStateMixin {
  // Controllers
  final LanguageController _languageController = Get.find<LanguageController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  // Terminal state
  final List<TerminalOutputModel> _outputs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocus = FocusNode();

  // Helper classes
  late final TerminalCommandHandler _commandHandler;
  final TypingAnimation _typingAnimation = TypingAnimation();

  // Animation controller
  late final AnimationController _animationController;

  // Terminal title and prefix
  String _terminalTitle = '';
  String _terminalPrefix = '>';

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
    _initializeAnimations();
    _showWelcomeMessage();
  }

  /// Initializes terminal components
  void _initializeTerminal() {
    // Create command handler
    _commandHandler = TerminalCommandHandler(
      languageController: _languageController,
      addOutput: _addOutput,
      clearTerminal: _clearTerminal,
      scrollToBottom: _scrollToBottom,
    );

    // Set terminal title
    _terminalTitle = _languageController.getText(
      'terminal.title',
      defaultValue: 'Terminal',
    );

    _terminalPrefix = _languageController.getText(
      'terminal.prefix',
      defaultValue: '>',
    );
  }

  /// Initializes animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();
  }

  /// Displays the welcome message
  void _showWelcomeMessage() {
    // Get welcome message
    final welcomeMessage = _languageController.getText(
      'terminal.welcome',
      defaultValue: 'Interactive terminal portföyüme hoş geldiniz!',
    );

    final helpHint = _languageController.getText(
      'terminal.help_hint',
      defaultValue: 'Kullanılabilir komutları görmek için "help" yazın.',
    );

    // Add welcome message
    _addOutput(
      TerminalOutputModel(
        content: welcomeMessage,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isBold: true,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );

    // Add help hint
    _addOutput(
      TerminalOutputModel(
        content: helpHint,
        type: TerminalOutputType.system,
        color: Colors.cyanAccent,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  /// Adds terminal output
  void _addOutput(TerminalOutputModel output) {
    setState(() {
      _outputs.add(output);

      // Start typing animation if enabled
      if (output.isTyping) {
        _typingAnimation.simulateTyping(
          output: output,
          onComplete: _scrollToBottom,
          setState: setState,
        );
      } else {
        _scrollToBottom();
      }
    });
  }

  /// Clears the terminal screen
  void _clearTerminal() {
    setState(_outputs.clear);
  }

  /// Scrolls to the bottom of the terminal
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Handles command submission
  void _handleCommandSubmit(String command) {
    _commandController.clear();

    if (command.trim().isEmpty) return;

    // Add command to output
    _addOutput(
      TerminalOutputModel(
        content: command,
        type: TerminalOutputType.command,
        isTyping: false,
        isCompleted: true,
        currentIndex: command.length,
      ),
    );

    _commandHandler.handleCommand(command);
    _terminalFocus.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commandController.dispose();
    _terminalFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeInUp(
      duration: const Duration(milliseconds: 800),
      from: 50,
      child: SizedBox(
        width: double.infinity,
        // Screen height minus AppBar height
        height: MediaQuery.of(context).size.height - 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(),

              const SizedBox(height: 16),
              Flexible(
                child: TerminalWidget(
                  outputs: _outputs,
                  scrollController: _scrollController,
                  title: _terminalTitle,
                  terminalPrefix: _terminalPrefix,
                  commandController: _commandController,
                  terminalFocus: _terminalFocus,
                  onSubmitCommand: _handleCommandSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  /// Builds the section title
  Widget _buildSectionTitle() => SectionTitle(
      title: _languageController.getText(
        'about_section.title',
        defaultValue: 'Hakkımda',
      ),
      useGlow: false,
      padding: const EdgeInsets.only(left: 8.0, bottom: 0),
      titleStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _themeController.isDarkMode ? Colors.white : Colors.black,
      ),
    );
}
