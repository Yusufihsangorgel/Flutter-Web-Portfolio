import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'dart:math' as math;

class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection>
    with SingleTickerProviderStateMixin {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  final TextEditingController _commandController = TextEditingController();
  final FocusNode _terminalFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Terminal çıktıları
  final List<TerminalOutputModel> _outputs = <TerminalOutputModel>[];

  // Kullanılabilir komutlar
  final List<String> _availableCommands = [
    'help',
    'about',
    'skills',
    'experience',
    'education',
    'projects',
    'contact',
    'social',
    'download-cv',
    'clear',
  ];

  // Terminal karakter animasyonu
  late AnimationController _cursorBlinkController;
  String _terminalPrefix = '>';
  final RxBool _isLoading = false.obs;

  // Star field animation
  final List<Star> _stars = [];
  final int _starCount = 100;

  @override
  void initState() {
    super.initState();

    // İmleç animasyonu başlat
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Yıldızları oluştur
    _generateStars();

    // Terminal başlat
    _initializeTerminal();

    // Terminal'e odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _terminalFocus.requestFocus();
    });
  }

  void _generateStars() {
    final random = math.Random();
    for (int i = 0; i < _starCount; i++) {
      _stars.add(
        Star(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2 + 0.5,
          brightness: random.nextDouble(),
          blinkDuration: Duration(milliseconds: random.nextInt(3000) + 1000),
        ),
      );
    }
  }

  /// Terminal çıkışı başlat
  void _initializeTerminal() {
    setState(() {
      _outputs.clear();
      _outputs.add(
        TerminalOutputModel(
          content:
              'Yusuf İhsan Görgel - Terminal\n'
              '${DateTime.now().toString().split('.').first}\n'
              '\n'
              '${languageController.getText('terminal.welcome_text')}\n',
          type: TerminalOutputType.system,
          color: themeController.isDarkMode ? Colors.green : Colors.teal,
          prefix: '',
          isBold: false,
          isTyping: false,
          isCompleted: true,
          currentIndex: 0,
        ),
      );
      _addOutput(
        '${languageController.getText('terminal.help_hint')}',
        type: TerminalOutputType.system,
        color: themeController.isDarkMode ? Colors.cyan : Colors.blue.shade700,
      );
    });
  }

  @override
  void dispose() {
    _cursorBlinkController.dispose();
    _commandController.dispose();
    _terminalFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addOutput(
    String text, {
    TerminalOutputType type = TerminalOutputType.text,
    Color? color,
    bool isBold = false,
  }) {
    // Determine color
    Color textColor;
    switch (type) {
      case TerminalOutputType.command:
        textColor = Colors.cyanAccent;
        break;
      case TerminalOutputType.error:
        textColor = Colors.redAccent;
        break;
      case TerminalOutputType.system:
        textColor = Colors.greenAccent;
        break;
      default:
        textColor = Colors.white;
    }

    setState(() {
      _outputs.add(
        TerminalOutputModel(
          content: text,
          type: type,
          color: color ?? textColor,
          isBold: isBold,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addTypingOutput(
    String text, {
    TerminalOutputType type = TerminalOutputType.text,
    int typingSpeed = 20,
    Color? color,
    bool isBold = false,
  }) {
    int currentIndex = 0;

    // Determine color
    Color textColor;
    switch (type) {
      case TerminalOutputType.command:
        textColor = Colors.cyanAccent;
        break;
      case TerminalOutputType.error:
        textColor = Colors.redAccent;
        break;
      case TerminalOutputType.system:
        textColor = Colors.greenAccent;
        break;
      default:
        textColor = Colors.white;
    }

    final output = TerminalOutputModel(
      content: '',
      type: type,
      isTyping: true,
      color: color ?? textColor,
      isBold: isBold,
    );

    setState(() {
      _outputs.add(output);
    });
    _scrollToBottom();

    // Simulate typing
    Timer.periodic(Duration(milliseconds: typingSpeed), (timer) {
      if (currentIndex < text.length) {
        setState(() {
          output.content += text[currentIndex];
          output.currentIndex = currentIndex + 1;
        });
        _scrollToBottom();

        currentIndex++;
      } else {
        setState(() {
          output.isTyping = false;
          output.isCompleted = true;
        });
        timer.cancel();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        try {
          final maxScroll = _scrollController.position.maxScrollExtent;
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('Scroll error: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight * 0.7),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 800 ? 100 : 20,
          vertical: 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                languageController.getText(
                  'about_section.title',
                  defaultValue: 'About Me',
                ),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: themeController.primaryColor,
                  shadows: [
                    Shadow(
                      color: themeController.primaryColor.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Space-themed Terminal
            Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: screenWidth > 800 ? screenWidth * 0.75 : screenWidth,
                  height: 500,
                  decoration: BoxDecoration(
                    color: const Color(0xFF000510),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Stars background
                        StarField(stars: _stars),

                        Column(
                          children: [
                            // Terminal header
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.3),
                                    Colors.purple.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.cyanAccent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Terminal title
                                  Text(
                                    languageController.getText(
                                      'terminal.title',
                                      defaultValue: 'COSMIC TERMINAL',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Terminal content
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _terminalFocus.requestFocus(),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Terminal outputs
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children:
                                              _outputs.map((output) {
                                                if (output.type ==
                                                    TerminalOutputType
                                                        .command) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '$_terminalPrefix ',
                                                          style: const TextStyle(
                                                            color:
                                                                Colors
                                                                    .cyanAccent,
                                                            fontFamily:
                                                                'monospace',
                                                            fontSize: 14,
                                                            height: 1.5,
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: SingleChildScrollView(
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            child: Text(
                                                              output.content,
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontFamily:
                                                                    'monospace',
                                                                fontSize: 14,
                                                                height: 1.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child:
                                                        output.content.isEmpty
                                                            ? const SizedBox(
                                                              height: 8,
                                                            )
                                                            : SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              child: Text(
                                                                output.content,
                                                                style: TextStyle(
                                                                  color:
                                                                      output
                                                                          .color,
                                                                  fontFamily:
                                                                      'monospace',
                                                                  fontSize: 14,
                                                                  height: 1.5,
                                                                  fontWeight:
                                                                      output.isBold
                                                                          ? FontWeight
                                                                              .bold
                                                                          : FontWeight
                                                                              .normal,
                                                                ),
                                                              ),
                                                            ),
                                                  );
                                                }
                                              }).toList(),
                                        ),

                                        // Command input
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$_terminalPrefix ',
                                              style: const TextStyle(
                                                color: Colors.cyanAccent,
                                                fontFamily: 'monospace',
                                                fontSize: 14,
                                                height: 1.5,
                                              ),
                                            ),
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _commandController,
                                                      focusNode: _terminalFocus,
                                                      autofocus: true,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'monospace',
                                                        fontSize: 14,
                                                        height: 1.5,
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                            border:
                                                                InputBorder
                                                                    .none,
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                          ),
                                                      onSubmitted:
                                                          _executeCommand,
                                                    ),
                                                  ),
                                                  AnimatedBuilder(
                                                    animation:
                                                        _cursorBlinkController,
                                                    builder: (context, child) {
                                                      return Opacity(
                                                        opacity:
                                                            _cursorBlinkController
                                                                        .value >
                                                                    0.5
                                                                ? 1.0
                                                                : 0.0,
                                                        child: const Text(
                                                          '█',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .cyanAccent,
                                                            fontFamily:
                                                                'monospace',
                                                            fontSize: 14,
                                                            height: 1.5,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Komutu çalıştırır
  void _executeCommand(String command) {
    _addOutput('$_terminalPrefix $command', type: TerminalOutputType.command);

    final lowercase = command.toLowerCase().trim();
    LanguageController languageController = Get.find<LanguageController>();

    if (lowercase == 'help') {
      _showHelp();
    } else if (lowercase == 'about') {
      _showAbout();
    } else if (lowercase == 'skills') {
      _showSkills();
    } else if (lowercase == 'education') {
      _showEducation();
    } else if (lowercase == 'experience') {
      _showExperience();
    } else if (lowercase == 'projects') {
      _showProjects();
    } else if (lowercase == 'contact') {
      _showContact();
    } else if (lowercase == 'social') {
      _showSocial();
    } else if (lowercase == 'download-cv' || lowercase == 'download cv') {
      _downloadCV();
    } else if (lowercase == 'clear') {
      _clearTerminal();
    } else {
      _addOutput(
        languageController
            .getText('terminal.command_not_found')
            .replaceAll('%s', command),
        type: TerminalOutputType.error,
      );
    }

    _commandController.clear();
  }

  void _showError(String message) {
    _addOutput(message, type: TerminalOutputType.error);
  }

  void _showHelp() {
    LanguageController languageController = Get.find<LanguageController>();
    String helpText = '';

    // Add title
    helpText += '${languageController.getText('terminal.commands.help')}\n\n';

    // List all commands
    helpText += '${languageController.getText('terminal.commands.help')}\n';
    helpText += '${languageController.getText('terminal.commands.about')}\n';
    helpText += '${languageController.getText('terminal.commands.skills')}\n';
    helpText +=
        '${languageController.getText('terminal.commands.experience')}\n';
    helpText +=
        '${languageController.getText('terminal.commands.education')}\n';
    helpText += '${languageController.getText('terminal.commands.projects')}\n';
    helpText += '${languageController.getText('terminal.commands.contact')}\n';
    helpText += '${languageController.getText('terminal.commands.social')}\n';
    helpText +=
        '${languageController.getText('terminal.commands.download-cv')}\n';
    helpText += '${languageController.getText('terminal.commands.clear')}\n';

    _addOutput(helpText, type: TerminalOutputType.system);
  }

  void _showAbout() {
    LanguageController languageController = Get.find<LanguageController>();
    final cvData = languageController.cvData;
    if (cvData == null || cvData['personal_info'] == null) {
      _addOutput(
        'No about information available',
        type: TerminalOutputType.error,
      );
      return;
    }

    final personalInfo = cvData['personal_info'];
    String aboutText = '';

    // Add name and title
    if (personalInfo['name'] != null && personalInfo['title'] != null) {
      aboutText += '${personalInfo['name']} - ${personalInfo['title']}\n\n';
    }

    // Add bio information
    if (personalInfo['bio'] != null) {
      aboutText += '${personalInfo['bio']}\n\n';
    }

    // Add contact information
    if (personalInfo['email'] != null) {
      aboutText +=
          '${languageController.getText('translations.email')}: ${personalInfo['email']}\n';
    }

    if (personalInfo['phone'] != null) {
      aboutText +=
          '${languageController.getText('translations.phone')}: ${personalInfo['phone']}\n';
    }

    if (personalInfo['location'] != null) {
      aboutText +=
          '${languageController.getText('translations.location')}: ${personalInfo['location']}\n';
    }

    if (personalInfo['github'] != null) {
      aboutText +=
          '${languageController.getText('translations.github')}: ${personalInfo['github']}\n';
    }

    if (personalInfo['linkedin'] != null) {
      aboutText +=
          '${languageController.getText('translations.linkedin')}: ${personalInfo['linkedin']}\n';
    }

    _addOutput(aboutText, type: TerminalOutputType.system);
  }

  void _showSkills() {
    final title = languageController.getText(
      'about_section.skills_title',
      defaultValue: 'SKILLS',
    );

    // JSON yapısı: cv_data.skills[].category ve cv_data.skills[].items
    final skillsData = languageController.cvData['skills'] ?? [];
    final Map<String, List<String>> skillsByCategory = {};

    for (var skillCategory in skillsData) {
      final category = skillCategory['category'] ?? 'Other';
      final items = skillCategory['items'] ?? [];

      if (items.isNotEmpty) {
        skillsByCategory[category] = List<String>.from(items);
      }
    }

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    if (skillsByCategory.isEmpty) {
      _addOutput(
        languageController.getText(
          'about_section.skills_not_available',
          defaultValue: 'No skills data available.',
        ),
        color: Colors.grey,
      );
      return;
    }

    skillsByCategory.forEach((category, skills) {
      _addOutput('◆ $category', isBold: true, color: Colors.greenAccent);
      for (var skill in skills) {
        _addOutput('  • $skill');
      }
      _addOutput('');
    });
  }

  void _showExperience() {
    final title = languageController.getText(
      'about_section.experience_title',
      defaultValue: 'EXPERIENCE',
    );

    final experiences = languageController.cvData['experiences'] ?? [];

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    if (experiences.isEmpty) {
      _addOutput(
        languageController.getText(
          'about_section.experience_not_available',
          defaultValue: 'No experience data available.',
        ),
        color: Colors.grey,
      );
      return;
    }

    for (var exp in experiences) {
      final company = exp['company'] ?? '';
      final position =
          exp['title'] ?? ''; // JSON'da position değil title olarak geçiyor
      final period = exp['period'] ?? '';
      final description = exp['description'] ?? '';

      _addOutput('◆ $company', isBold: true, color: Colors.greenAccent);
      _addOutput('  $position');
      _addOutput('  $period');
      if (description.isNotEmpty) {
        _addOutput('');
        _addOutput('  $description');
      }
      _addOutput('');
    }
  }

  void _showEducation() {
    final title = languageController.getText(
      'about_section.education_title',
      defaultValue: 'EDUCATION',
    );

    final educations =
        languageController.cvData['education'] ??
        []; // JSON'da educations değil education olarak geçiyor

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    if (educations.isEmpty) {
      _addOutput(
        languageController.getText(
          'about_section.education_not_available',
          defaultValue: 'No education data available.',
        ),
        color: Colors.grey,
      );
      return;
    }

    for (var edu in educations) {
      final school = edu['school'] ?? '';
      final department =
          edu['degree'] ?? ''; // JSON'da department değil degree olarak geçiyor
      final period = edu['period'] ?? '';

      _addOutput('◆ $school', isBold: true, color: Colors.greenAccent);
      if (department.isNotEmpty) _addOutput('  $department');
      _addOutput('  $period');
      _addOutput('');
    }
  }

  void _showProjects() {
    final title = languageController.getText(
      'about_section.projects_title',
      defaultValue: 'PROJECTS',
    );

    final projects = languageController.cvData['projects'] ?? [];

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    if (projects.isEmpty) {
      _addOutput(
        languageController.getText(
          'about_section.projects_not_available',
          defaultValue: 'No project data available.',
        ),
        color: Colors.grey,
      );
      return;
    }

    for (var project in projects) {
      final name = project['title'] ?? '';
      final desc = project['description'] ?? '';

      // URL bilgisini kontrol et
      String url = '';
      if (project['url'] is String) {
        url = project['url'];
      } else if (project['url'] is Map) {
        final urls = project['url'] as Map;
        if (urls.containsKey('website')) {
          url = urls['website'];
        } else if (urls.containsKey('google_play')) {
          url = urls['google_play'];
        } else if (urls.containsKey('app_store')) {
          url = urls['app_store'];
        }
      }

      _addOutput('◆ $name', isBold: true, color: Colors.greenAccent);
      _addOutput('  $desc');
      if (url.isNotEmpty) {
        _addOutput('  $url', color: Colors.blueAccent);
      }
      _addOutput('');
    }
  }

  void _showContact() {
    final title = languageController.getText(
      'about_section.contact_title',
      defaultValue: 'CONTACT',
    );

    // JSON yapısı: cv_data.personal_info içerisinde
    final personalInfo = languageController.cvData['personal_info'] ?? {};

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    final email = personalInfo['email'] ?? '';
    final phone = personalInfo['phone'] ?? '';
    final location = personalInfo['location'] ?? '';

    if (email.isNotEmpty) _addOutput('◆ Email     : $email');
    if (phone.isNotEmpty) _addOutput('◆ Phone     : $phone');
    if (location.isNotEmpty) _addOutput('◆ Location  : $location');

    _addOutput('');
  }

  void _showSocial() {
    final title = languageController.getText(
      'about_section.social_title',
      defaultValue: 'SOCIAL PROFILES',
    );

    // JSON yapısı: cv_data.personal_info içerisinde
    final personalInfo = languageController.cvData['personal_info'] ?? {};

    _addOutput('');
    _addOutput('【 $title 】', isBold: true, color: Colors.cyanAccent);
    _addOutput('');

    final github = personalInfo['github'] ?? '';
    final linkedin = personalInfo['linkedin'] ?? '';
    final twitter = personalInfo['twitter'] ?? '';

    if (github.isNotEmpty) _addOutput('◆ GitHub   : $github');
    if (linkedin.isNotEmpty) _addOutput('◆ LinkedIn : $linkedin');
    if (twitter.isNotEmpty) _addOutput('◆ Twitter  : $twitter');

    _addOutput('');
  }

  // CV İndirme fonksiyonu
  Future<void> _downloadCV() async {
    _addOutput('');
    _addOutput(
      languageController.getText(
        'terminal.download_cv_start',
        defaultValue: 'Initiating CV download...',
      ),
      color: Colors.yellowAccent,
    );

    const cvUrl = '/assets/data/cv.pdf';

    try {
      if (await canLaunchUrl(Uri.parse(cvUrl))) {
        await launchUrl(Uri.parse(cvUrl));
        _addOutput(
          languageController.getText(
            'terminal.download_cv_success',
            defaultValue: 'CV download started in your browser.',
          ),
          color: Colors.greenAccent,
        );
      } else {
        // Fallback method - open in browser
        final baseUrl = Uri.base.toString();
        final fullUrl = baseUrl + cvUrl;
        await launchUrl(Uri.parse(fullUrl));
        _addOutput(
          languageController.getText(
            'terminal.download_cv_fallback',
            defaultValue: 'CV opened in your browser.',
          ),
          color: Colors.greenAccent,
        );
      }
    } catch (e) {
      _showError(
        languageController.getText(
          'terminal.download_cv_error',
          defaultValue: 'Error downloading CV. Please try again later.',
        ),
      );
    }
  }

  // Terminal ekranını temizler
  void _clearTerminal() {
    setState(() {
      _outputs.clear();
      _initializeTerminal();
    });
  }
}

// Terminal çıktı türleri
enum TerminalOutputType { text, command, error, system }

// Terminal çıktı modeli
class TerminalOutputModel {
  String content;
  TerminalOutputType type;
  Color color;
  String prefix;
  bool isBold;
  bool isTyping;
  bool isCompleted;
  int currentIndex;

  TerminalOutputModel({
    required this.content,
    this.type = TerminalOutputType.text,
    this.color = Colors.white,
    this.prefix = '',
    this.isBold = false,
    this.isTyping = false,
    this.isCompleted = false,
    this.currentIndex = 0,
  });
}

// Star class for animation
class Star {
  final double x;
  final double y;
  final double size;
  final double brightness;
  final Duration blinkDuration;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.blinkDuration,
  });
}

// Star field widget
class StarField extends StatefulWidget {
  final List<Star> stars;

  const StarField({super.key, required this.stars});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = [];
    _animations = [];

    for (var star in widget.stars) {
      final controller = AnimationController(
        vsync: this,
        duration: star.blinkDuration,
      );

      final animation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _controllers.add(controller);
      _animations.add(animation);

      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StarPainter(stars: widget.stars, animations: _animations),
      size: Size.infinite,
    );
  }
}

// Star painter
class StarPainter extends CustomPainter {
  final List<Star> stars;
  final List<Animation<double>> animations;

  StarPainter({required this.stars, required this.animations});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final animation = animations[i];

      final paint =
          Paint()
            ..color = Colors.white.withOpacity(
              star.brightness * animation.value,
            )
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => true;
}
