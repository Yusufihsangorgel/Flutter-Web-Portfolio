import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';
import 'package:flutter_web_portfolio/app/utils/url_launcher_utils.dart';

/// Handles terminal command processing
class TerminalCommandHandler {

  TerminalCommandHandler({
    required LanguageController languageController,
    required this.addOutput,
    required this.clearTerminal,
    required this.scrollToBottom,
  }) : _languageController = languageController;
  final LanguageController _languageController;
  final Function(TerminalOutputModel) addOutput;
  final VoidCallback clearTerminal;
  final VoidCallback scrollToBottom;

  /// Processes a command and produces the appropriate response
  void handleCommand(String command) {
    if (command.isEmpty) return;

    final lowercaseCommand = command.toLowerCase().trim();
    final commands = _getLocalizedCommands();

    // Match against both localized and English fallback commands
    if (lowercaseCommand == commands['help'] || lowercaseCommand == 'help') {
      _showHelp();
    } else if (lowercaseCommand == commands['about'] ||
        lowercaseCommand == 'about') {
      _showAbout();
    } else if (lowercaseCommand == commands['skills'] ||
        lowercaseCommand == 'skills') {
      _showSkills();
    } else if (lowercaseCommand == commands['education'] ||
        lowercaseCommand == 'education') {
      _showEducation();
    } else if (lowercaseCommand == commands['experience'] ||
        lowercaseCommand == 'experience') {
      _showExperience();
    } else if (lowercaseCommand == commands['projects'] ||
        lowercaseCommand == 'projects') {
      _showProjects();
    } else if (lowercaseCommand == commands['contact'] ||
        lowercaseCommand == 'contact') {
      _showContact();
    } else if (lowercaseCommand == commands['social'] ||
        lowercaseCommand == 'social') {
      _showSocial();
    } else if (lowercaseCommand == commands['download_cv'] ||
        lowercaseCommand == 'download-cv' ||
        lowercaseCommand == 'download cv') {
      _downloadCV();
    } else if (lowercaseCommand == commands['clear'] ||
        lowercaseCommand == 'clear') {
      clearTerminal();
    } else {
      _showCommandNotFound(command);
    }
  }

  /// Returns localized command names
  Map<String, String> _getLocalizedCommands() => {
      'help':
          _languageController
              .getText('terminal.commands.help_cmd', defaultValue: 'help')
              .toLowerCase(),

      'about':
          _languageController
              .getText('terminal.commands.about_cmd', defaultValue: 'about')
              .toLowerCase(),

      'skills':
          _languageController
              .getText('terminal.commands.skills_cmd', defaultValue: 'skills')
              .toLowerCase(),

      'education':
          _languageController
              .getText(
                'terminal.commands.education_cmd',
                defaultValue: 'education',
              )
              .toLowerCase(),

      'experience':
          _languageController
              .getText(
                'terminal.commands.experience_cmd',
                defaultValue: 'experience',
              )
              .toLowerCase(),

      'projects':
          _languageController
              .getText(
                'terminal.commands.projects_cmd',
                defaultValue: 'projects',
              )
              .toLowerCase(),

      'contact':
          _languageController
              .getText('terminal.commands.contact_cmd', defaultValue: 'contact')
              .toLowerCase(),

      'social':
          _languageController
              .getText('terminal.commands.social_cmd', defaultValue: 'social')
              .toLowerCase(),

      'download_cv':
          _languageController
              .getText(
                'terminal.commands.download_cv_cmd',
                defaultValue: 'download-cv',
              )
              .toLowerCase(),

      'clear':
          _languageController
              .getText('terminal.commands.clear_cmd', defaultValue: 'clear')
              .toLowerCase(),
    };

  void _showHelp() {
    final commands = _getLocalizedCommands();

    final helpDesc = _languageController.getText(
      'terminal.commands.help',
      defaultValue: 'displays available commands',
    );
    final aboutDesc = _languageController.getText(
      'terminal.commands.about',
      defaultValue: 'shows personal information',
    );
    final skillsDesc = _languageController.getText(
      'terminal.commands.skills',
      defaultValue: 'displays technical skills',
    );
    final experienceDesc = _languageController.getText(
      'terminal.commands.experience',
      defaultValue: 'shows work experience',
    );
    final educationDesc = _languageController.getText(
      'terminal.commands.education',
      defaultValue: 'shows education history',
    );
    final projectsDesc = _languageController.getText(
      'terminal.commands.projects',
      defaultValue: 'shows completed projects',
    );
    final contactDesc = _languageController.getText(
      'terminal.commands.contact',
      defaultValue: 'shows contact information',
    );
    final socialDesc = _languageController.getText(
      'terminal.commands.social',
      defaultValue: 'shows social media profiles',
    );
    final downloadCvDesc = _languageController.getText(
      'terminal.commands.download_cv',
      defaultValue: 'downloads my CV',
    );
    final clearDesc = _languageController.getText(
      'terminal.commands.clear',
      defaultValue: 'clears terminal screen',
    );

    String helpText = '';

    helpText +=
        '${_languageController.getText('terminal.help_title', defaultValue: 'Available Commands:')}\n\n';

    helpText += '${commands['help']} - $helpDesc\n';
    helpText += '${commands['about']} - $aboutDesc\n';
    helpText += '${commands['skills']} - $skillsDesc\n';
    helpText += '${commands['experience']} - $experienceDesc\n';
    helpText += '${commands['education']} - $educationDesc\n';
    helpText += '${commands['projects']} - $projectsDesc\n';
    helpText += '${commands['contact']} - $contactDesc\n';
    helpText += '${commands['social']} - $socialDesc\n';
    helpText += '${commands['download_cv']} - $downloadCvDesc\n';
    helpText += '${commands['clear']} - $clearDesc\n';

    addOutput(
      TerminalOutputModel(
        content: helpText,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  void _showAbout() {
    final cvData = _languageController.cvData;
    if (cvData['personal_info'] == null) {
      addOutput(
        TerminalOutputModel(
          content: 'No about information available',
          type: TerminalOutputType.error,
          color: Colors.redAccent,
          isTyping: false,
          isCompleted: true,
          currentIndex: 'No about information available'.length,
        ),
      );
      return;
    }

    final personalInfo = cvData['personal_info'];
    String aboutText = '';

    final name = personalInfo['name'];
    final title = personalInfo['title'];
    if (name != null && title != null) {
      aboutText += '$name - $title\n\n';
    }

    final bio = personalInfo['bio'];
    if (bio != null) {
      aboutText += '$bio\n\n';
    }

    final contactFields = {
      'email': 'translations.email',
      'phone': 'translations.phone',
      'location': 'translations.location',
      'github': 'translations.github',
      'linkedin': 'translations.linkedin',
    };

    contactFields.forEach((key, translationKey) {
      if (personalInfo[key] != null) {
        final label = _languageController.getText(
          translationKey,
          defaultValue: key.toUpperCase(),
        );
        aboutText += '$label: ${personalInfo[key]}\n';
      }
    });

    addOutput(
      TerminalOutputModel(
        content: aboutText,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  void _showSkills() {
    final title = _languageController.getText(
      'about_section.skills_title',
      defaultValue: 'SKILLS',
    );

    final skillsData = _languageController.cvData['skills'] ?? [];
    final Map<String, List<String>> skillsByCategory = {};

    for (var skillCategory in skillsData) {
      final category = skillCategory['category'] ?? 'Other';
      final items = skillCategory['items'] ?? [];

      if (items.isNotEmpty) {
        skillsByCategory[category] = List<String>.from(items);
      }
    }

    String skillsText = '\n【 $title 】\n\n';

    if (skillsByCategory.isEmpty) {
      skillsText += _languageController.getText(
        'about_section.skills_not_available',
        defaultValue: 'No skills data available.',
      );
    } else {
      skillsByCategory.forEach((category, skills) {
        skillsText += '◆ $category\n';
        for (var skill in skills) {
          skillsText += '  • $skill\n';
        }
        skillsText += '\n';
      });
    }

    addOutput(
      TerminalOutputModel(
        content: skillsText,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isBold: false,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  void _showExperience() {
    final title = _languageController.getText(
      'about_section.experience_title',
      defaultValue: 'EXPERIENCE',
    );

    final experiences = _languageController.cvData['experiences'] ?? [];

    String experienceText = '\n【 $title 】\n\n';

    if (experiences.isEmpty) {
      experienceText += _languageController.getText(
        'about_section.experience_not_available',
        defaultValue: 'No experience data available.',
      );
    } else {
      for (var exp in experiences) {
        final company = exp['company'] ?? '';
        final position = exp['title'] ?? '';
        final period = exp['period'] ?? '';
        final description = exp['description'] ?? '';

        experienceText += '◆ $company\n';
        experienceText += '  $position\n';
        experienceText += '  $period\n';
        if (description.isNotEmpty) {
          experienceText += '\n  $description\n';
        }
        experienceText += '\n';
      }
    }

    addOutput(
      TerminalOutputModel(
        content: experienceText,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isBold: false,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  void _showEducation() {
    final title = _languageController.getText(
      'about_section.education_title',
      defaultValue: 'EDUCATION',
    );

    final educations = _languageController.cvData['education'] ?? [];

    String educationText = '\n【 $title 】\n\n';

    if (educations.isEmpty) {
      educationText += _languageController.getText(
        'about_section.education_not_available',
        defaultValue: 'No education data available.',
      );
    } else {
      for (var edu in educations) {
        final school = edu['school'] ?? '';
        final department = edu['degree'] ?? '';
        final period = edu['period'] ?? '';

        educationText += '◆ $school\n';
        if (department.isNotEmpty) educationText += '  $department\n';
        educationText += '  $period\n\n';
      }
    }

    addOutput(
      TerminalOutputModel(
        content: educationText,
        type: TerminalOutputType.system,
        color: Colors.greenAccent,
        isBold: false,
        isTyping: true,
        isCompleted: false,
        currentIndex: 0,
      ),
    );
  }

  void _showProjects() {
    final projects = _languageController.cvData['projects'] ?? [];

    final title = _languageController.getText(
      'terminal.projects.title',
      defaultValue: 'MY PROJECTS',
    );

    String projectsText = '\n【 $title 】\n\n';

    if (projects.isEmpty) {
      projectsText += _languageController.getText(
        'terminal.projects.not_found',
        defaultValue: 'No projects found.',
      );

      addOutput(
        TerminalOutputModel(
          content: projectsText,
          type: TerminalOutputType.system,
          color: Colors.greenAccent,
          isBold: false,
          isTyping: true,
          isCompleted: false,
          currentIndex: 0,
        ),
      );
    } else {
      addOutput(
        TerminalOutputModel(
          content: '\n【 $title 】\n\n',
          type: TerminalOutputType.system,
          color: Colors.cyanAccent,
          isBold: true,
          isTyping: false,
          isCompleted: true,
          currentIndex: '\n【 $title 】\n\n'.length,
        ),
      );

      for (final project in projects) {
        final title =
            project['title'] ??
            _languageController.getText(
              'terminal.projects.untitled',
              defaultValue: 'Untitled',
            );
        final description = project['description'] ?? '';
        final url = _extractUrl(project);

        addOutput(
          TerminalOutputModel(
            content: '◆ $title',
            type: TerminalOutputType.system,
            color: Colors.greenAccent,
            isBold: true,
            isTyping: false,
            isCompleted: true,
            currentIndex: '◆ $title'.length,
          ),
        );

        if (description.isNotEmpty) {
          addOutput(
            TerminalOutputModel(
              content: '  $description',
              type: TerminalOutputType.system,
              color: Colors.white,
              isBold: false,
              isTyping: false,
              isCompleted: true,
              currentIndex: '  $description'.length,
            ),
          );
        }

        if (url.isNotEmpty) {
          addOutput(
            TerminalOutputModel(
              content: '  $url',
              type: TerminalOutputType.system,
              color: Colors.blueAccent,
              isBold: false,
              isTyping: false,
              isCompleted: true,
              currentIndex: '  $url'.length,
              onTap: () => _launchUrl(url),
            ),
          );
        }

        addOutput(
          TerminalOutputModel(
            content: '',
            type: TerminalOutputType.system,
            color: Colors.white,
            isBold: false,
            isTyping: false,
            isCompleted: true,
            currentIndex: 0,
          ),
        );
      }
    }
  }

  void _showContact() {
    final title = _languageController.getText(
      'about_section.contact_title',
      defaultValue: 'CONTACT',
    );

    final personalInfo = _languageController.cvData['personal_info'] ?? {};

    addOutput(
      TerminalOutputModel(
        content: '\n【 $title 】\n',
        type: TerminalOutputType.system,
        color: Colors.cyanAccent,
        isBold: true,
        isTyping: false,
        isCompleted: true,
        currentIndex: '\n【 $title 】\n'.length,
      ),
    );

    final email = personalInfo['email'] ?? '';
    final phone = personalInfo['phone'] ?? '';
    final location = personalInfo['location'] ?? '';

    final emailLabel = _languageController.getText(
      'terminal.contact.email',
      defaultValue: 'Email',
    );
    final phoneLabel = _languageController.getText(
      'terminal.contact.phone',
      defaultValue: 'Phone',
    );
    final locationLabel = _languageController.getText(
      'terminal.contact.location',
      defaultValue: 'Location',
    );

    if (email.isNotEmpty) {
      addOutput(
        TerminalOutputModel(
          content: '◆ $emailLabel     : $email',
          type: TerminalOutputType.system,
          color: Colors.white,
          isBold: false,
          isTyping: false,
          isCompleted: true,
          currentIndex: '◆ $emailLabel     : $email'.length,
          onTap: () => _launchUrl('mailto:$email'),
        ),
      );
    }

    if (phone.isNotEmpty) {
      addOutput(
        TerminalOutputModel(
          content: '◆ $phoneLabel     : $phone',
          type: TerminalOutputType.system,
          color: Colors.white,
          isBold: false,
          isTyping: false,
          isCompleted: true,
          currentIndex: '◆ $phoneLabel     : $phone'.length,
          onTap: () => _launchUrl('tel:${phone.replaceAll(' ', '')}'),
        ),
      );
    }

    if (location.isNotEmpty) {
      addOutput(
        TerminalOutputModel(
          content: '◆ $locationLabel  : $location',
          type: TerminalOutputType.system,
          color: Colors.white,
          isBold: false,
          isTyping: false,
          isCompleted: true,
          currentIndex: '◆ $locationLabel  : $location'.length,
        ),
      );
    }

    addOutput(
      TerminalOutputModel(
        content: '',
        type: TerminalOutputType.system,
        color: Colors.white,
        isBold: false,
        isTyping: false,
        isCompleted: true,
        currentIndex: 0,
      ),
    );
  }

  void _showSocial() {
    final title = _languageController.getText(
      'about_section.social_title',
      defaultValue: 'SOCIAL PROFILES',
    );

    final personalInfo = _languageController.cvData['personal_info'] ?? {};

    addOutput(
      TerminalOutputModel(
        content: '\n【 $title 】\n',
        type: TerminalOutputType.system,
        color: Colors.cyanAccent,
        isBold: true,
        isTyping: false,
        isCompleted: true,
        currentIndex: '\n【 $title 】\n'.length,
      ),
    );

    final socialProfiles = {
      _languageController.getText(
            'terminal.social.github',
            defaultValue: 'GitHub',
          ):
          personalInfo['github'] ?? '',

      _languageController.getText(
            'terminal.social.linkedin',
            defaultValue: 'LinkedIn',
          ):
          personalInfo['linkedin'] ?? '',

      _languageController.getText(
            'terminal.social.twitter',
            defaultValue: 'Twitter',
          ):
          personalInfo['twitter'] ?? '',
    };

    socialProfiles.forEach((platform, url) {
      if (url != null && url.isNotEmpty) {
        addOutput(
          TerminalOutputModel(
            content: '◆ $platform : $url',
            type: TerminalOutputType.system,
            color: Colors.white,
            isBold: false,
            isTyping: false,
            isCompleted: true,
            currentIndex: '◆ $platform : $url'.length,
            onTap: () => _launchUrl(url as String),
          ),
        );
      }
    });

    addOutput(
      TerminalOutputModel(
        content: '',
        type: TerminalOutputType.system,
        color: Colors.white,
        isBold: false,
        isTyping: false,
        isCompleted: true,
        currentIndex: 0,
      ),
    );
  }

  Future<void> _downloadCV() async {
    final startMessage = _languageController.getText(
      'terminal.download_cv_start',
      defaultValue: 'Initiating CV download...',
    );

    addOutput(
      TerminalOutputModel(
        content: startMessage,
        type: TerminalOutputType.system,
        color: Colors.yellowAccent,
        isTyping: false,
        isCompleted: true,
        currentIndex: startMessage.length,
      ),
    );

    const cvUrl = '/assets/data/cv.pdf';

    try {
      final baseUrl = Uri.base.toString();
      final fullUrl = baseUrl + cvUrl;

      UrlLauncherUtils.openUrl(
        url: fullUrl,
        onSuccess: () {
          final successMessage = _languageController.getText(
            'terminal.download_cv_success',
            defaultValue: 'CV download started in your browser.',
          );

          addOutput(
            TerminalOutputModel(
              content: successMessage,
              type: TerminalOutputType.system,
              color: Colors.greenAccent,
              isTyping: false,
              isCompleted: true,
              currentIndex: successMessage.length,
            ),
          );
        },
        onError: (error) {
          final errorMessage = _languageController.getText(
            'terminal.download_cv_error',
            defaultValue: 'Error downloading CV. Please try again later.',
          );

          addOutput(
            TerminalOutputModel(
              content: '$errorMessage ($error)',
              type: TerminalOutputType.error,
              color: Colors.redAccent,
              isTyping: false,
              isCompleted: true,
              currentIndex: '$errorMessage ($error)'.length,
            ),
          );
        },
      );
    } catch (e) {
      final errorMessage =
          '${_languageController.getText('terminal.download_cv_error', defaultValue: 'Error downloading CV. Please try again later.')} (Error: $e)';

      addOutput(
        TerminalOutputModel(
          content: errorMessage,
          type: TerminalOutputType.error,
          color: Colors.redAccent,
          isTyping: false,
          isCompleted: true,
          currentIndex: errorMessage.length,
        ),
      );
    }
  }

  void _showCommandNotFound(String command) {
    final errorMessage = _languageController
        .getText('terminal.command_not_found')
        .replaceAll('%s', command);

    addOutput(
      TerminalOutputModel(
        content: errorMessage,
        type: TerminalOutputType.error,
        color: Colors.redAccent,
        isTyping: false,
        isCompleted: true,
        currentIndex: errorMessage.length,
      ),
    );
  }

  void _launchUrl(String url) {
    UrlLauncherUtils.openUrl(
      url: url,
      onSuccess: () {
        final successMessage = _languageController.getText(
          'terminal.url.success',
          defaultValue: 'Opening link in browser...',
        );

        addOutput(
          TerminalOutputModel(
            content: successMessage,
            type: TerminalOutputType.system,
            color: Colors.greenAccent,
            isTyping: false,
            isCompleted: true,
            currentIndex: successMessage.length,
          ),
        );
      },
      onError: (error) {
        final errorMessage = _languageController.getText(
          'terminal.url.error_with_details',
          defaultValue: 'Error launching URL',
        );

        addOutput(
          TerminalOutputModel(
            content: '$errorMessage: $error',
            type: TerminalOutputType.error,
            color: Colors.redAccent,
            isTyping: false,
            isCompleted: true,
            currentIndex: '$errorMessage: $error'.length,
          ),
        );
      },
    );
  }

  /// Extracts the best available URL from a project map
  String _extractUrl(Map<dynamic, dynamic> project) {
    if (project['url'] is String) {
      return project['url'] as String;
    } else if (project['url'] is Map) {
      final urls = project['url'] as Map;
      for (final key in ['website', 'google_play', 'app_store']) {
        if (urls.containsKey(key)) {
          return urls[key] as String;
        }
      }
    }
    return '';
  }
}
