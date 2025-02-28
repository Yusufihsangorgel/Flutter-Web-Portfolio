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

/// Hakkımda bölümü - Terminal arayüzü ile kullanıcı etkileşimi sağlar
class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection>
    with SingleTickerProviderStateMixin {
  // Kontrolcüler
  final LanguageController _languageController = Get.find<LanguageController>();
  final ThemeController _themeController = Get.find<ThemeController>();

  // Terminal durumu
  final List<TerminalOutputModel> _outputs = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocus = FocusNode();

  // Yardımcı sınıflar
  late final TerminalCommandHandler _commandHandler;
  final TypingAnimation _typingAnimation = TypingAnimation();

  // Animasyon kontrolcüsü
  late final AnimationController _animationController;

  // Terminal başlığı ve öneki
  String _terminalTitle = '';
  String _terminalPrefix = '>';

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
    _initializeAnimations();
    _showWelcomeMessage();
  }

  /// Terminal bileşenlerini başlatır
  void _initializeTerminal() {
    // Komut işleyiciyi oluştur
    _commandHandler = TerminalCommandHandler(
      languageController: _languageController,
      addOutput: _addOutput,
      clearTerminal: _clearTerminal,
      scrollToBottom: _scrollToBottom,
    );

    // Terminal başlığını ayarla
    _terminalTitle = _languageController.getText(
      'terminal.title',
      defaultValue: 'Terminal',
    );

    _terminalPrefix = _languageController.getText(
      'terminal.prefix',
      defaultValue: '>',
    );
  }

  /// Animasyonları başlatır
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();
  }

  /// Karşılama mesajını gösterir
  void _showWelcomeMessage() {
    // Karşılama mesajını al
    final welcomeMessage = _languageController.getText(
      'terminal.welcome',
      defaultValue: 'Interactive terminal portföyüme hoş geldiniz!',
    );

    final helpHint = _languageController.getText(
      'terminal.help_hint',
      defaultValue: 'Kullanılabilir komutları görmek için "help" yazın.',
    );

    // Karşılama mesajını ekle
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

    // Yardım ipucunu ekle
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

  /// Terminal çıktısı ekler
  void _addOutput(TerminalOutputModel output) {
    setState(() {
      _outputs.add(output);

      // Yazma animasyonu varsa başlat
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

  /// Terminal ekranını temizler
  void _clearTerminal() {
    setState(() {
      _outputs.clear();
    });
  }

  /// Ekranı en alta kaydırır
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

  /// Komut gönderildiğinde çalışır
  void _handleCommandSubmit(String command) {
    // Komut kontrolcüsünü temizle
    _commandController.clear();

    // Boş komut kontrolü
    if (command.trim().isEmpty) return;

    // Komutu çıktılara ekle
    _addOutput(
      TerminalOutputModel(
        content: command,
        type: TerminalOutputType.command,
        isTyping: false,
        isCompleted: true,
        currentIndex: command.length,
      ),
    );

    // Komutu işle
    _commandHandler.handleCommand(command);

    // Terminale odaklan
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
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      from: 50,
      child: SizedBox(
        width: double.infinity,
        // Ekran yüksekliği - AppBar yüksekliği
        height: MediaQuery.of(context).size.height - 80,
        // Üst ve alt padding'i azaltıyoruz - özellikle üst kısımdaki padding'i
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bölüm başlığı
              _buildSectionTitle(),

              const SizedBox(height: 16), // Daha az boşluk
              // Terminal arayüzü
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
  }

  /// Bölüm başlığını oluşturur
  Widget _buildSectionTitle() {
    return SectionTitle(
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
}
