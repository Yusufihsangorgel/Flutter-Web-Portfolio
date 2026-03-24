import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';

// =============================================================================
// PremiumContactForm
// =============================================================================

/// A premium, fully-animated contact form with floating labels, custom dropdown,
/// liquid submit button, confetti success state, social links, and
/// copy-to-clipboard functionality.
class PremiumContactForm extends StatefulWidget {
  const PremiumContactForm({super.key});

  @override
  State<PremiumContactForm> createState() => _PremiumContactFormState();
}

enum _FormStatus { idle, sending, success, error }

class _PremiumContactFormState extends State<PremiumContactForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedSubject = '';
  _FormStatus _status = _FormStatus.idle;

  // Entrance stagger
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fieldEntrances;

  // Success state
  late final AnimationController _successCtrl;
  late final Animation<double> _formSlideUp;
  late final Animation<double> _successFadeIn;

  // Confetti
  late final AnimationController _confettiCtrl;
  final List<_ConfettiParticle> _confettiParticles = [];

  // Progress
  final _nameValid = ValueNotifier(false);
  final _emailValid = ValueNotifier(false);
  final _subjectValid = ValueNotifier(false);
  final _messageValid = ValueNotifier(false);

  // Toast
  bool _showToast = false;

  static const _subjectKeys = [
    'project',
    'collaboration',
    'job_opportunity',
    'consulting',
    'general',
    'other',
  ];

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 6 staggered fields: name, email, subject, message, button, social
    _fieldEntrances = List.generate(6, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(start, end, curve: CinematicCurves.dramaticEntrance),
      );
    });

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formSlideUp = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(
        parent: _successCtrl,
        curve: const Interval(0.0, 0.5, curve: CinematicCurves.dramaticEntrance),
      ),
    );
    _successFadeIn = CurvedAnimation(
      parent: _successCtrl,
      curve: const Interval(0.4, 1.0, curve: CinematicCurves.revealDecel),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _nameController.addListener(_updateProgress);
    _emailController.addListener(_updateProgress);
    _messageController.addListener(_updateProgress);

    // Trigger entrance after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _successCtrl.dispose();
    _confettiCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _nameValid.dispose();
    _emailValid.dispose();
    _subjectValid.dispose();
    _messageValid.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _nameValid.value = _nameController.text.trim().isNotEmpty;
    final emailText = _emailController.text.trim();
    _emailValid.value = emailText.isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(emailText);
    _messageValid.value = _messageController.text.trim().isNotEmpty;
  }

  void _onSubjectChanged(String subject) {
    setState(() => _selectedSubject = subject);
    _subjectValid.value = subject.isNotEmpty;
  }

  double get _completionProgress {
    int filled = 0;
    if (_nameValid.value) filled++;
    if (_emailValid.value) filled++;
    if (_subjectValid.value) filled++;
    if (_messageValid.value) filled++;
    return filled / 4;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedSubject.isEmpty) {
      _subjectValid.value = false;
      return;
    }

    setState(() => _status = _FormStatus.sending);

    try {
      final languageController = Get.find<LanguageController>();
      final formspreeId =
          languageController.cvData['contact']?['formspree_id'] as String? ??
              '';
      final formspreeEndpoint = 'https://formspree.io/f/$formspreeId';

      final response = await http
          .post(
            Uri.parse(formspreeEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'subject': _selectedSubject,
              'message': _messageController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _status = _FormStatus.success);
        _generateConfetti();
        _confettiCtrl.forward(from: 0);
        _successCtrl.forward(from: 0);

        // Auto-reset after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _status == _FormStatus.success) {
            _resetForm();
          }
        });
      } else {
        setState(() => _status = _FormStatus.error);
        Future.delayed(AppDurations.formResetDelay, () {
          if (mounted) setState(() => _status = _FormStatus.idle);
        });
      }
    } catch (e) {
      dev.log('Form submission failed', name: 'PremiumContactForm', error: e);
      if (!mounted) return;
      setState(() => _status = _FormStatus.error);
      Future.delayed(AppDurations.formResetDelay, () {
        if (mounted) setState(() => _status = _FormStatus.idle);
      });
    }
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    _selectedSubject = '';
    _nameValid.value = false;
    _emailValid.value = false;
    _subjectValid.value = false;
    _messageValid.value = false;
    _successCtrl.reverse();
    setState(() => _status = _FormStatus.idle);
  }

  void _generateConfetti() {
    final rng = math.Random();
    _confettiParticles.clear();
    for (int i = 0; i < 40; i++) {
      _confettiParticles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.3,
        vx: (rng.nextDouble() - 0.5) * 2,
        vy: -rng.nextDouble() * 3 - 1,
        rotation: rng.nextDouble() * math.pi * 2,
        rotationSpeed: (rng.nextDouble() - 0.5) * 8,
        size: rng.nextDouble() * 6 + 3,
        color: [
          AppColors.heroAccent,
          AppColors.expAccent,
          AppColors.aboutAccent,
          AppColors.projAccent,
          const Color(0xFF8B5CF6),
          const Color(0xFFEC4899),
        ][rng.nextInt(6)],
      ));
    }
  }

  void _copyEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    setState(() => _showToast = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LanguageController>();
    final data = lang.cvData['personal_info'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final email = (data['email'] as String?) ?? 'developeryusuf@icloud.com';

    return Obx(() {
      final accent = Get.find<SceneDirector>().currentAccent.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Main form content
          AnimatedBuilder(
            animation: _successCtrl,
            builder: (context, child) {
              if (_status == _FormStatus.success && _successCtrl.value > 0.4) {
                return _buildSuccessState(accent, lang);
              }

              return Transform.translate(
                offset: Offset(0, _formSlideUp.value * 60),
                child: Opacity(
                  opacity: (1 - _successCtrl.value).clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: _buildForm(accent, lang, email),
          ),

          // Confetti overlay
          if (_status == _FormStatus.success)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress: _confettiCtrl.value,
                        particles: _confettiParticles,
                      ),
                    );
                  },
                ),
              ),
            ),

          // Toast notification
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedSlide(
                offset: _showToast ? const Offset(0, -1) : Offset.zero,
                duration: AppDurations.medium,
                curve: CinematicCurves.dramaticEntrance,
                child: AnimatedOpacity(
                  opacity: _showToast ? 1.0 : 0.0,
                  duration: AppDurations.fast,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.3), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          'Email copied!',
                          style: AppTypography.bodySmall.copyWith(color: accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildForm(Color accent, LanguageController lang, String email) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress bar
          _buildProgressBar(accent),
          const SizedBox(height: 32),

          // Name field
          _StaggeredEntry(
            animation: _fieldEntrances[0],
            child: _PremiumTextField(
              controller: _nameController,
              label: lang.getText(
                  'contact_section.form.name_label', defaultValue: 'Name'),
              icon: Icons.person_outline,
              accent: accent,
              textInputAction: TextInputAction.next,
              validNotifier: _nameValid,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText('contact_section.form.name_error',
                      defaultValue: 'Please enter your name');
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          // Email field
          _StaggeredEntry(
            animation: _fieldEntrances[1],
            child: _PremiumTextField(
              controller: _emailController,
              label: lang.getText(
                  'contact_section.form.email_label', defaultValue: 'Email'),
              icon: Icons.email_outlined,
              accent: accent,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validNotifier: _emailValid,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText('contact_section.form.email_error',
                      defaultValue: 'Please enter a valid email');
                }
                if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(value.trim())) {
                  return lang.getText('contact_section.form.email_error',
                      defaultValue: 'Please enter a valid email');
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          // Subtle divider
          _StaggeredEntry(
            animation: _fieldEntrances[2],
            child: _buildDivider(accent),
          ),
          const SizedBox(height: 24),

          // Subject dropdown
          _StaggeredEntry(
            animation: _fieldEntrances[2],
            child: _PremiumDropdown(
              label: lang.getText('contact_section.form.subject_label',
                  defaultValue: 'Subject'),
              icon: Icons.subject_outlined,
              accent: accent,
              selectedValue: _selectedSubject,
              options: _subjectKeys
                  .map((key) => _DropdownOption(
                        value: key,
                        label: lang.getText(
                          'contact_section.form.subjects.$key',
                          defaultValue: _defaultSubjectLabel(key),
                        ),
                      ))
                  .toList(),
              onChanged: _onSubjectChanged,
            ),
          ),
          const SizedBox(height: 24),

          // Message field with character count
          _StaggeredEntry(
            animation: _fieldEntrances[3],
            child: _PremiumMessageField(
              controller: _messageController,
              label: lang.getText('contact_section.form.message_label',
                  defaultValue: 'Message'),
              accent: accent,
              validNotifier: _messageValid,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang.getText('contact_section.form.message_error',
                      defaultValue: 'Please enter your message');
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          _StaggeredEntry(
            animation: _fieldEntrances[4],
            child: _PremiumSubmitButton(
              accent: accent,
              status: _status,
              onTap: _status == _FormStatus.sending ? null : _submit,
            ),
          ),
          const SizedBox(height: 40),

          // Divider before social
          _StaggeredEntry(
            animation: _fieldEntrances[5],
            child: _buildDivider(accent),
          ),
          const SizedBox(height: 24),

          // Social links row
          _StaggeredEntry(
            animation: _fieldEntrances[5],
            child: _SocialLinksRow(accent: accent),
          ),
          const SizedBox(height: 20),

          // "Or email me directly" with copy button
          _StaggeredEntry(
            animation: _fieldEntrances[5],
            child: _DirectEmailRow(
              email: email,
              accent: accent,
              onCopy: () => _copyEmail(email),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color accent) {
    return ListenableBuilder(
      listenable: Listenable.merge([_nameValid, _emailValid, _subjectValid, _messageValid]),
      builder: (context, _) {
        final progress = _completionProgress;
        return Container(
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: AppDurations.medium,
                    curve: CinematicCurves.dramaticEntrance,
                    width: constraints.maxWidth * progress,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.3),
                          accent,
                        ],
                      ),
                      boxShadow: progress > 0
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDivider(Color accent) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(Color accent, LanguageController lang) {
    return FadeTransition(
      opacity: _successFadeIn,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
          // Party popper icon with bounce
          _BounceCheckmark(accent: accent),
          const SizedBox(height: 24),
          Text(
            lang.getText('contact_section.form.success',
                defaultValue: 'Your message has been sent successfully!'),
            style: AppTypography.h2.copyWith(color: accent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            lang.getText('contact_section.form.success_subtitle',
                defaultValue: 'I\'ll get back to you as soon as possible.'),
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // "Send Another Message" button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _resetForm,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: accent.withValues(alpha: 0.4), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  lang.getText('contact_section.form.send_another',
                      defaultValue: 'Send Another Message'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: accent,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  String _defaultSubjectLabel(String key) {
    switch (key) {
      case 'project':
        return 'Project Inquiry';
      case 'collaboration':
        return 'Collaboration';
      case 'job_opportunity':
        return 'Job Opportunity';
      case 'consulting':
        return 'Consulting';
      case 'general':
        return 'General Question';
      case 'other':
        return 'Other';
      default:
        return key;
    }
  }
}

// =============================================================================
// _StaggeredEntry - Wraps child with entrance animation
// =============================================================================

class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// _PremiumTextField - Floating label, expanding underline, icon, validation
// =============================================================================

class _PremiumTextField extends StatefulWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.validNotifier,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueNotifier<bool>? validNotifier;

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField>
    with TickerProviderStateMixin {
  bool _focused = false;
  bool _hasText = false;
  String? _errorText;
  bool _showSuccess = false;

  late final AnimationController _underlineCtrl;
  late final AnimationController _successCtrl;

  @override
  void initState() {
    super.initState();
    _underlineCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _underlineCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Live validation for success state
    if (widget.validNotifier != null && widget.validator != null && hasText) {
      final error = widget.validator!(widget.controller.text);
      final isValid = error == null;
      if (isValid && !_showSuccess) {
        setState(() {
          _showSuccess = true;
          _errorText = null;
        });
        _successCtrl.forward(from: 0);
      } else if (!isValid && _showSuccess) {
        setState(() => _showSuccess = false);
        _successCtrl.reverse();
      }
    }
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _focused = hasFocus);
    if (hasFocus) {
      _underlineCtrl.forward();
    } else {
      _underlineCtrl.reverse();
      // Validate on blur
      if (widget.validator != null) {
        final error = widget.validator!(widget.controller.text);
        setState(() {
          _errorText = error;
          _showSuccess = error == null && widget.controller.text.isNotEmpty;
        });
        if (_showSuccess) {
          _successCtrl.forward(from: 0);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFloating = _focused || _hasText;
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field container
        Focus(
          onFocusChange: _onFocusChange,
          child: AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            decoration: BoxDecoration(
              color: _focused
                  ? widget.accent.withValues(alpha: 0.04)
                  : Colors.transparent,
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Icon
                      AnimatedContainer(
                        duration: AppDurations.fast,
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: hasError
                              ? AppColors.projAccent
                              : _focused
                                  ? widget.accent
                                  : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Input with floating label
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Floating label
                            AnimatedPositioned(
                              duration: AppDurations.fast,
                              curve: CinematicCurves.hoverLift,
                              top: isFloating ? -18 : 2,
                              left: 0,
                              child: AnimatedDefaultTextStyle(
                                duration: AppDurations.fast,
                                style: GoogleFonts.inter(
                                  fontSize: isFloating ? 11 : 15,
                                  fontWeight: FontWeight.w400,
                                  color: hasError
                                      ? AppColors.projAccent
                                      : _focused
                                          ? widget.accent
                                          : AppColors.textSecondary,
                                  letterSpacing: isFloating ? 0.5 : 0,
                                ),
                                child: Text(widget.label),
                              ),
                            ),
                            // Text input
                            Padding(
                              padding: const EdgeInsets.only(top: 0),
                              child: TextFormField(
                                controller: widget.controller,
                                keyboardType: widget.keyboardType,
                                textInputAction: widget.textInputAction,
                                style: AppTypography.body
                                    .copyWith(color: AppColors.textBright),
                                cursorColor: widget.accent,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                // Use internal validation only
                                validator: (value) {
                                  final error = widget.validator?.call(value);
                                  // Update error display via setState after frame
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() => _errorText = error);
                                    }
                                  });
                                  return error;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Success checkmark
                      AnimatedBuilder(
                        animation: _successCtrl,
                        builder: (context, _) {
                          if (!_showSuccess) return const SizedBox.shrink();
                          return Transform.scale(
                            scale: Curves.elasticOut
                                .transform(_successCtrl.value.clamp(0.0, 1.0)),
                            child: Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.expAccent
                                  .withValues(alpha: _successCtrl.value),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Animated underline (expands from center)
                AnimatedBuilder(
                  animation: _underlineCtrl,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        // Base line
                        Container(
                          height: 1,
                          color: hasError
                              ? AppColors.projAccent.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        // Expanding accent line
                        Center(
                          child: Container(
                            height: 2,
                            width: _underlineCtrl.value *
                                MediaQuery.sizeOf(context).width,
                            decoration: BoxDecoration(
                              color: hasError
                                  ? AppColors.projAccent
                                  : widget.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: (hasError
                                          ? AppColors.projAccent
                                          : widget.accent)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Error message (slides in)
        AnimatedSize(
          duration: AppDurations.fast,
          curve: CinematicCurves.hoverLift,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 46),
                  child: AnimatedSlide(
                    offset: hasError ? Offset.zero : const Offset(0, -0.5),
                    duration: AppDurations.fast,
                    child: Text(
                      _errorText!,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.projAccent),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// =============================================================================
// _PremiumDropdown - Custom styled dropdown with staggered options
// =============================================================================

class _DropdownOption {
  const _DropdownOption({required this.value, required this.label});
  final String value;
  final String label;
}

class _PremiumDropdown extends StatefulWidget {
  const _PremiumDropdown({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String selectedValue;
  final List<_DropdownOption> options;
  final ValueChanged<String> onChanged;

  @override
  State<_PremiumDropdown> createState() => _PremiumDropdownState();
}

class _PremiumDropdownState extends State<_PremiumDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  late final AnimationController _dropCtrl;

  @override
  void initState() {
    super.initState();
    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _dropCtrl.forward();
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _dropCtrl.reverse().then((_) {
      _removeOverlay();
    });
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  void _selectOption(String value) {
    widget.onChanged(value);
    _closeDropdown();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          // Dropdown options
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 4),
              showWhenUnlinked: false,
              child: AnimatedBuilder(
                animation: _dropCtrl,
                builder: (context, _) {
                  return Transform.scale(
                    scaleY: _dropCtrl.value,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: _dropCtrl.value,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            border: Border.all(
                              color:
                                  widget.accent.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.options.length,
                              (index) {
                                final option = widget.options[index];
                                final isSelected = option.value ==
                                    widget.selectedValue;
                                final staggerDelay =
                                    index * 0.08;
                                final itemProgress =
                                    ((_dropCtrl.value - staggerDelay) /
                                            (1 - staggerDelay))
                                        .clamp(0.0, 1.0);

                                return Transform.translate(
                                  offset: Offset(
                                      0, 10 * (1 - itemProgress)),
                                  child: Opacity(
                                    opacity: itemProgress,
                                    child: _DropdownItem(
                                      option: option,
                                      isSelected: isSelected,
                                      accent: widget.accent,
                                      onTap: () =>
                                          _selectOption(option.value),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.selectedValue.isNotEmpty;
    final selectedLabel = hasValue
        ? widget.options
            .firstWhere((o) => o.value == widget.selectedValue,
                orElse: () => _DropdownOption(
                    value: '', label: widget.selectedValue))
            .label
        : null;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppDurations.buttonHover,
                curve: CinematicCurves.hoverLift,
                decoration: BoxDecoration(
                  color: _isOpen
                      ? widget.accent.withValues(alpha: 0.04)
                      : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Icon(
                            widget.icon,
                            size: 18,
                            color: _isOpen
                                ? widget.accent
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Stack(
                              children: [
                                // Floating label
                                AnimatedPositioned(
                                  duration: AppDurations.fast,
                                  curve: CinematicCurves.hoverLift,
                                  top: hasValue ? -12 : 2,
                                  left: 0,
                                  child: AnimatedDefaultTextStyle(
                                    duration: AppDurations.fast,
                                    style: GoogleFonts.inter(
                                      fontSize: hasValue ? 11 : 15,
                                      fontWeight: FontWeight.w400,
                                      color: _isOpen
                                          ? widget.accent
                                          : AppColors.textSecondary,
                                      letterSpacing:
                                          hasValue ? 0.5 : 0,
                                    ),
                                    child: Text(widget.label),
                                  ),
                                ),
                                // Selected value
                                if (hasValue)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 2),
                                    child: Text(
                                      selectedLabel ?? '',
                                      style: AppTypography.body.copyWith(
                                          color: AppColors.textBright),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          // Success checkmark or chevron
                          if (hasValue && !_isOpen)
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.expAccent,
                            )
                          else
                            AnimatedRotation(
                              turns: _isOpen ? 0.5 : 0,
                              duration: AppDurations.fast,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: _isOpen
                                    ? widget.accent
                                    : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Underline
                    Stack(
                      children: [
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        AnimatedContainer(
                          duration: AppDurations.medium,
                          curve: CinematicCurves.hoverLift,
                          height: 2,
                          width: _isOpen
                              ? MediaQuery.sizeOf(context).width
                              : 0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.accent,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.accent.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  const _DropdownItem({
    required this.option,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final _DropdownOption option;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDurations.microFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _hovered
              ? widget.accent.withValues(alpha: 0.08)
              : widget.isSelected
                  ? widget.accent.withValues(alpha: 0.04)
                  : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.option.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: widget.isSelected
                        ? widget.accent
                        : AppColors.textBright,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check, size: 16, color: widget.accent),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _PremiumMessageField - Auto-expanding textarea with character count
// =============================================================================

class _PremiumMessageField extends StatefulWidget {
  const _PremiumMessageField({
    required this.controller,
    required this.label,
    required this.accent,
    this.validator,
    this.validNotifier,
  });

  final TextEditingController controller;
  final String label;
  final Color accent;
  final String? Function(String?)? validator;
  final ValueNotifier<bool>? validNotifier;

  @override
  State<_PremiumMessageField> createState() => _PremiumMessageFieldState();
}

class _PremiumMessageFieldState extends State<_PremiumMessageField>
    with TickerProviderStateMixin {
  bool _focused = false;
  bool _hasText = false;
  String? _errorText;
  int _charCount = 0;

  late final AnimationController _underlineCtrl;
  late final AnimationController _successCtrl;
  bool _showSuccess = false;

  static const _maxChars = 2000;

  @override
  void initState() {
    super.initState();
    _underlineCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.medium,
    );
    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _underlineCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    setState(() {
      _hasText = text.isNotEmpty;
      _charCount = text.length;
    });

    if (widget.validator != null && _hasText) {
      final error = widget.validator!(text);
      final isValid = error == null;
      if (isValid && !_showSuccess) {
        setState(() {
          _showSuccess = true;
          _errorText = null;
        });
        _successCtrl.forward(from: 0);
      } else if (!isValid && _showSuccess) {
        setState(() => _showSuccess = false);
        _successCtrl.reverse();
      }
    }
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _focused = hasFocus);
    if (hasFocus) {
      _underlineCtrl.forward();
    } else {
      _underlineCtrl.reverse();
      if (widget.validator != null) {
        final error = widget.validator!(widget.controller.text);
        setState(() {
          _errorText = error;
          _showSuccess = error == null && widget.controller.text.isNotEmpty;
        });
        if (_showSuccess) _successCtrl.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFloating = _focused || _hasText;
    final hasError = _errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: _onFocusChange,
          child: AnimatedContainer(
            duration: AppDurations.buttonHover,
            curve: CinematicCurves.hoverLift,
            decoration: BoxDecoration(
              color: _focused
                  ? widget.accent.withValues(alpha: 0.04)
                  : Colors.transparent,
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.06),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: hasError
                                  ? AppColors.projAccent
                                  : _focused
                                      ? widget.accent
                                      : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Floating label
                                AnimatedPositioned(
                                  duration: AppDurations.fast,
                                  curve: CinematicCurves.hoverLift,
                                  top: isFloating ? -18 : 4,
                                  left: 0,
                                  child: AnimatedDefaultTextStyle(
                                    duration: AppDurations.fast,
                                    style: GoogleFonts.inter(
                                      fontSize: isFloating ? 11 : 15,
                                      fontWeight: FontWeight.w400,
                                      color: hasError
                                          ? AppColors.projAccent
                                          : _focused
                                              ? widget.accent
                                              : AppColors.textSecondary,
                                      letterSpacing:
                                          isFloating ? 0.5 : 0,
                                    ),
                                    child: Text(widget.label),
                                  ),
                                ),
                                // Textarea
                                Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: TextFormField(
                                    controller: widget.controller,
                                    maxLines: null,
                                    minLines: 4,
                                    maxLength: _maxChars,
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.textBright),
                                    cursorColor: widget.accent,
                                    buildCounter: (context,
                                        {required currentLength,
                                        required isFocused,
                                        required maxLength}) {
                                      // We handle counter ourselves
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    validator: (value) {
                                      final error =
                                          widget.validator?.call(value);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(
                                              () => _errorText = error);
                                        }
                                      });
                                      return error;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Character count and success
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Success checkmark
                          AnimatedBuilder(
                            animation: _successCtrl,
                            builder: (context, _) {
                              if (!_showSuccess) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Transform.scale(
                                  scale: Curves.elasticOut.transform(
                                      _successCtrl.value.clamp(0.0, 1.0)),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.expAccent.withValues(
                                        alpha: _successCtrl.value),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Animated character count
                          TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: _charCount),
                            duration: AppDurations.fast,
                            builder: (context, count, _) {
                              return Text(
                                '$count / $_maxChars',
                                style: AppTypography.caption.copyWith(
                                  color: _charCount > _maxChars * 0.9
                                      ? AppColors.projAccent
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.6),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Animated underline
                AnimatedBuilder(
                  animation: _underlineCtrl,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 1,
                          color: hasError
                              ? AppColors.projAccent.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                        Center(
                          child: Container(
                            height: 2,
                            width: _underlineCtrl.value *
                                MediaQuery.sizeOf(context).width,
                            decoration: BoxDecoration(
                              color: hasError
                                  ? AppColors.projAccent
                                  : widget.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: (hasError
                                          ? AppColors.projAccent
                                          : widget.accent)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // Error message
        AnimatedSize(
          duration: AppDurations.fast,
          curve: CinematicCurves.hoverLift,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 46),
                  child: Text(
                    _errorText!,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.projAccent),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// =============================================================================
// _PremiumSubmitButton - Liquid-style button with state transitions
// =============================================================================

class _PremiumSubmitButton extends StatefulWidget {
  const _PremiumSubmitButton({
    required this.accent,
    required this.status,
    required this.onTap,
  });

  final Color accent;
  final _FormStatus status;
  final VoidCallback? onTap;

  @override
  State<_PremiumSubmitButton> createState() => _PremiumSubmitButtonState();
}

class _PremiumSubmitButtonState extends State<_PremiumSubmitButton>
    with TickerProviderStateMixin {
  bool _hovered = false;

  late final AnimationController _morphCtrl;
  late final AnimationController _fillCtrl;
  late final AnimationController _pressCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _successCheckCtrl;

  @override
  void initState() {
    super.initState();
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successCheckCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void didUpdateWidget(covariant _PremiumSubmitButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      switch (widget.status) {
        case _FormStatus.success:
          _successCheckCtrl.forward(from: 0);
          break;
        case _FormStatus.error:
          _shakeCtrl.forward(from: 0);
          break;
        default:
          break;
      }
    }
  }

  @override
  void dispose() {
    _morphCtrl.dispose();
    _fillCtrl.dispose();
    _pressCtrl.dispose();
    _shakeCtrl.dispose();
    _successCheckCtrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (widget.status == _FormStatus.sending) return;
    setState(() => _hovered = true);
    _morphCtrl.repeat();
    _fillCtrl.forward();
  }

  void _onExit(PointerEvent _) {
    setState(() => _hovered = false);
    _morphCtrl.stop();
    _fillCtrl.reverse();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.status == _FormStatus.sending) return;
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = widget.status == _FormStatus.sending;
    final isSuccess = widget.status == _FormStatus.success;
    final isError = widget.status == _FormStatus.error;

    return MouseRegion(
      cursor: isSending
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _morphCtrl,
            _fillCtrl,
            _pressCtrl,
            _shakeCtrl,
            _successCheckCtrl,
          ]),
          builder: (context, _) {
            final scale = 1.0 - _pressCtrl.value * 0.04;
            // Shake offset for error
            final shakeOffset = isError
                ? math.sin(_shakeCtrl.value * math.pi * 6) *
                    8 *
                    (1 - _shakeCtrl.value)
                : 0.0;

            return Transform(
              transform: Matrix4.translationValues(shakeOffset, 0, 0)
                ..scale(scale, scale),
              alignment: Alignment.center,
              child: SizedBox(
                height: 56,
                child: CustomPaint(
                  painter: _LiquidSubmitPainter(
                    morphPhase: _morphCtrl.value,
                    fillProgress: _fillCtrl.value,
                    accentColor: isError
                        ? AppColors.projAccent
                        : isSuccess
                            ? AppColors.expAccent
                            : widget.accent,
                    hovered: _hovered,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: AppDurations.medium,
                      switchInCurve: CinematicCurves.dramaticEntrance,
                      switchOutCurve: CinematicCurves.dramaticEntrance,
                      transitionBuilder: (child, anim) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.6),
                            end: Offset.zero,
                          ).animate(anim),
                          child:
                              FadeTransition(opacity: anim, child: child),
                        );
                      },
                      child: _buildButtonContent(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    final buttonColor =
        _hovered ? AppColors.white : widget.accent;

    switch (widget.status) {
      case _FormStatus.sending:
        return Row(
          key: const ValueKey('sending'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(widget.accent),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sending...',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: widget.accent,
              ),
            ),
          ],
        );

      case _FormStatus.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: Curves.elasticOut
                  .transform(_successCheckCtrl.value.clamp(0.0, 1.0)),
              child: const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.expAccent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Sent!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.expAccent,
              ),
            ),
          ],
        );

      case _FormStatus.error:
        return Row(
          key: const ValueKey('error'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.close,
              size: 20,
              color: AppColors.projAccent,
            ),
            const SizedBox(width: 10),
            Text(
              'Failed',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.projAccent,
              ),
            ),
          ],
        );

      case _FormStatus.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, size: 18, color: buttonColor),
            const SizedBox(width: 10),
            Text(
              'Send Message',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: buttonColor,
              ),
            ),
          ],
        );
    }
  }
}

// =============================================================================
// _LiquidSubmitPainter - Liquid border painter for submit button
// =============================================================================

class _LiquidSubmitPainter extends CustomPainter {
  _LiquidSubmitPainter({
    required this.morphPhase,
    required this.fillProgress,
    required this.accentColor,
    required this.hovered,
  });

  final double morphPhase;
  final double fillProgress;
  final Color accentColor;
  final bool hovered;

  @override
  void paint(Canvas canvas, Size size) {
    // Fill
    if (fillProgress > 0) {
      final fillPath = _buildOrganicPath(size, morphPhase, amplitude: 0);
      final fillPaint = Paint()
        ..color = accentColor.withValues(alpha: fillProgress * 0.85)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.clipPath(fillPath);
      canvas.drawRect(
        Rect.fromLTRB(-10, -10, size.width + 10, size.height + 10),
        fillPaint,
      );
      canvas.restore();
    }

    // Organic border
    final amplitude = hovered ? 3.0 : 0.0;
    final borderPath =
        _buildOrganicPath(size, morphPhase, amplitude: amplitude);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovered ? 2.0 : 1.5
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          accentColor,
          accentColor.withValues(alpha: 0.5),
          accentColor,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawPath(borderPath, borderPaint);

    // Glow on hover
    if (hovered) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = accentColor.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(borderPath, glowPaint);
    }
  }

  Path _buildOrganicPath(Size size, double phase,
      {required double amplitude}) {
    final w = size.width;
    final h = size.height;
    final r = h * 0.35;
    final tau = math.pi * 2;

    double wobble(double base, int seed) {
      return base + math.sin(phase * tau + seed * 1.7) * amplitude;
    }

    final path = Path();
    path.moveTo(r, wobble(0, 0));

    path.cubicTo(
      w * 0.3, wobble(-amplitude * 0.6, 1),
      w * 0.7, wobble(amplitude * 0.6, 2),
      w - r, wobble(0, 3),
    );
    path.quadraticBezierTo(w, 0, w, r + wobble(0, 4));

    path.cubicTo(
      w + wobble(0, 5) * 0.5, h * 0.3,
      w + wobble(0, 6) * 0.5, h * 0.7,
      w, h - r + wobble(0, 7),
    );
    path.quadraticBezierTo(w, h, w - r, h + wobble(0, 8));

    path.cubicTo(
      w * 0.7, h + wobble(amplitude * 0.6, 9),
      w * 0.3, h + wobble(-amplitude * 0.6, 10),
      r, h + wobble(0, 11),
    );
    path.quadraticBezierTo(0, h, 0, h - r + wobble(0, 12));

    path.cubicTo(
      wobble(0, 13) * 0.5, h * 0.7,
      wobble(0, 14) * 0.5, h * 0.3,
      0, r + wobble(0, 15),
    );
    path.quadraticBezierTo(0, 0, r, wobble(0, 0));

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_LiquidSubmitPainter old) =>
      old.morphPhase != morphPhase ||
      old.fillProgress != fillProgress ||
      old.hovered != hovered ||
      old.accentColor != accentColor;
}

// =============================================================================
// _SocialLinksRow - Social icons with hover animations
// =============================================================================

class _SocialLinksRow extends StatelessWidget {
  const _SocialLinksRow({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final lang = Get.find<LanguageController>();
    final data = lang.cvData['personal_info'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final github = (data['github'] as String?) ?? '';
    final linkedin = (data['linkedin'] as String?) ?? '';
    final twitter = (data['twitter'] as String?) ?? '';
    final email = (data['email'] as String?) ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (github.isNotEmpty)
          _SocialIcon(
            icon: Icons.code_rounded,
            tooltip: 'GitHub',
            url: github,
            accent: accent,
          ),
        if (linkedin.isNotEmpty) ...[
          const SizedBox(width: 24),
          _SocialIcon(
            icon: Icons.business_center_outlined,
            tooltip: 'LinkedIn',
            url: linkedin,
            accent: accent,
          ),
        ],
        if (twitter.isNotEmpty) ...[
          const SizedBox(width: 24),
          _SocialIcon(
            icon: Icons.alternate_email_rounded,
            tooltip: 'Twitter / X',
            url: twitter,
            accent: accent,
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(width: 24),
          _SocialIcon(
            icon: Icons.email_outlined,
            tooltip: 'Email',
            url: 'mailto:$email',
            accent: accent,
          ),
        ],
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  const _SocialIcon({
    required this.icon,
    required this.tooltip,
    required this.url,
    required this.accent,
  });

  final IconData icon;
  final String tooltip;
  final String url;
  final Color accent;

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
      lowerBound: 1.0,
      upperBound: 1.2,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovered = true);
          _scaleCtrl.forward();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _scaleCtrl.reverse();
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            final uri = Uri.parse(widget.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: AnimatedBuilder(
            animation: _scaleCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleCtrl.value,
                child: child,
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hovered
                    ? widget.accent.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color: _hovered
                      ? widget.accent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 20,
                color: _hovered ? widget.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DirectEmailRow - "Or email me directly" with copy button
// =============================================================================

class _DirectEmailRow extends StatefulWidget {
  const _DirectEmailRow({
    required this.email,
    required this.accent,
    required this.onCopy,
  });

  final String email;
  final Color accent;
  final VoidCallback onCopy;

  @override
  State<_DirectEmailRow> createState() => _DirectEmailRowState();
}

class _DirectEmailRowState extends State<_DirectEmailRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Or email me directly',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 8),
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onCopy,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: AppDurations.fast,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _hovered
                          ? widget.accent
                          : AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                    child: Text(widget.email),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? widget.accent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: _hovered
                          ? widget.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _BounceCheckmark - Success state animated checkmark
// =============================================================================

class _BounceCheckmark extends StatefulWidget {
  const _BounceCheckmark({required this.accent});
  final Color accent;

  @override
  State<_BounceCheckmark> createState() => _BounceCheckmarkState();
}

class _BounceCheckmarkState extends State<_BounceCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final scale =
            Curves.elasticOut.transform(_ctrl.value.clamp(0.0, 1.0));
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent.withValues(alpha: 0.1),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 36,
              color: widget.accent,
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// _ConfettiParticle + _ConfettiPainter
// =============================================================================

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final opacity = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final t = progress;
      final gravity = 2.0;
      final px = (p.x + p.vx * t) * size.width;
      final py =
          (p.y + p.vy * t + gravity * t * t) * size.height;
      final rot = p.rotation + p.rotationSpeed * t;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
