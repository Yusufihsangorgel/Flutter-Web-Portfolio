import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_portfolio/app/features/language/application/language_cubit.dart';
import 'package:flutter_web_portfolio/app/controllers/sound_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/core/constants/cinematic_curves.dart';
import 'package:flutter_web_portfolio/app/core/constants/durations.dart';
import 'package:flutter_web_portfolio/app/core/theme/app_typography.dart';
import 'package:flutter_web_portfolio/app/features/contact/domain/contact_mailto.dart';
import 'package:flutter_web_portfolio/app/utils/responsive_utils.dart';
import 'package:flutter_web_portfolio/app/widgets/magnetic_button.dart';
import 'package:flutter_web_portfolio/app/widgets/numbered_section_heading.dart';
import 'package:flutter_web_portfolio/app/widgets/scroll_fade_in.dart';
import 'package:flutter_web_portfolio/app/widgets/scene_accent_builder.dart';

/// Contact Section — "The Finale"
/// White particles on deep black, shader reveal title, magnetic CTA button,
/// and a mail-client handoff that keeps visitor messages on their device.
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, _) => _buildContent(context),
      );

  Widget _buildContent(BuildContext context) {
    final languageController = context.read<LanguageCubit>();
    final data =
        languageController.cvData['personal_info'] as Map<String, dynamic>? ??
        <String, dynamic>{};
    final email = (data['email'] as String?) ?? 'hello@example.com';
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenSize.height * 0.6),
      child: Stack(
        children: [
          // Giant watermark — derived from nav i18n
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                languageController
                    .getText('nav.contact', defaultValue: 'Contact')
                    .toUpperCase(),
                style: AppFonts.spaceGrotesk(
                  fontSize: ResponsiveUtils.getValueForScreenType<double>(
                    context: context,
                    mobile: 48.0,
                    tablet: screenWidth * 0.14,
                    desktop: screenWidth * 0.18,
                  ),
                  fontWeight: FontWeight.w800,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withValues(alpha: 0.03),
                  letterSpacing: -2,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Title
                    ScrollFadeIn(
                      child: SceneAccentBuilder(
                        builder: (context, accent) => NumberedSectionHeading(
                          number: '06',
                          title: languageController.getText(
                            'contact_section.title',
                            defaultValue: 'Get In Touch',
                          ),
                          accent: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Description
                    ScrollFadeIn(
                      delay: AppDurations.staggerMedium,
                      child: Text(
                        languageController.getText(
                          'contact_section.description',
                          defaultValue:
                              'I\'m always open to new challenges and '
                              'collaborations. Whether you have a project idea, '
                              'a question, or just want to connect — feel free '
                              'to reach out!',
                        ),
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Magnetic CTA button
                    ScrollFadeIn(
                      delay: AppDurations.normal,
                      child: _MagneticCTA(email: email),
                    ),
                    const SizedBox(height: 40),
                    // "or" divider
                    ScrollFadeIn(
                      delay: AppDurations.staggerLong,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              languageController.getText(
                                'contact_section.form.or_divider',
                                defaultValue: 'or send a message directly',
                              ),
                              style: AppTypography.caption,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Contact Form
                    const ScrollFadeIn(
                      delay: AppDurations.staggerXLong,
                      child: _ContactForm(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Magnetic CTA — cursor-attracting "Say Hello"
class _MagneticCTA extends StatelessWidget {
  const _MagneticCTA({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) => SceneAccentBuilder(
    builder: (context, accent) {
      final label = context.read<LanguageCubit>().getText(
        'translations.send_message',
        defaultValue: 'Say Hello',
      );
      return Semantics(
        button: true,
        label: label,
        child: MagneticButton(
          onTap: () async {
            final uri = Uri.parse('mailto:$email');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
          child: _HoverContainer(accent: accent, label: label),
        ),
      );
    },
  );
}

class _HoverContainer extends StatefulWidget {
  const _HoverContainer({required this.accent, required this.label});
  final Color accent;
  final String label;

  @override
  State<_HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<_HoverContainer> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: AnimatedContainer(
      duration: AppDurations.buttonHover,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: _hovered
            ? widget.accent.withValues(alpha: 0.08)
            : Colors.transparent,
        border: Border.all(
          color: _hovered
              ? widget.accent
              : widget.accent.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: Text(
        widget.label,
        style: AppFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: widget.accent,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

/// Contact draft form with a local mail-client handoff.
class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

enum _FormStatus { idle, sending, success, error }

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  _FormStatus _status = _FormStatus.idle;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _status = _FormStatus.sending);

    try {
      final languageController = context.read<LanguageCubit>();
      final personalInfo =
          languageController.cvData['personal_info'] as Map<String, dynamic>?;
      final recipient = personalInfo?['email'] as String? ?? '';
      if (recipient.isEmpty) throw StateError('Contact email is unavailable');

      final mailto = buildContactMailtoUri(
        recipient: recipient,
        senderName: _nameController.text.trim(),
        senderEmail: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      final opened = await launchUrl(mailto);

      if (!mounted) return;
      if (opened) {
        context.read<SoundController>().playSuccess();
        setState(() => _status = _FormStatus.success);
        _resetStatusAfterDelay();
      } else {
        setState(() => _status = _FormStatus.error);
        _resetStatusAfterDelay();
      }
    } catch (error, stackTrace) {
      dev.log(
        'Mail client handoff failed',
        name: 'ContactForm',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _status = _FormStatus.error);
      _resetStatusAfterDelay();
    }
  }

  void _resetStatusAfterDelay() {
    Future<void>.delayed(AppDurations.formResetDelay, () {
      if (mounted) setState(() => _status = _FormStatus.idle);
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<LanguageCubit, LanguageState>(
    buildWhen: (previous, current) =>
        previous.languageCode != current.languageCode ||
        !identical(previous.translations, current.translations),
    builder: (context, languageState) {
      final lang = context.read<LanguageCubit>();
      return SceneAccentBuilder(
        builder: (context, accent) => Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              _CinematicTextField(
                controller: _nameController,
                label: lang.getText(
                  'contact_section.form.name_label',
                  defaultValue: 'Name',
                ),
                accent: accent,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.getText(
                      'contact_section.form.name_error',
                      defaultValue: 'Please enter your name',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email field
              _CinematicTextField(
                controller: _emailController,
                label: lang.getText(
                  'contact_section.form.email_label',
                  defaultValue: 'Email',
                ),
                accent: accent,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.getText(
                      'contact_section.form.email_error',
                      defaultValue: 'Please enter a valid email',
                    );
                  }
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return lang.getText(
                      'contact_section.form.email_error',
                      defaultValue: 'Please enter a valid email',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Message field
              _CinematicTextField(
                controller: _messageController,
                label: lang.getText(
                  'contact_section.form.message_label',
                  defaultValue: 'Message',
                ),
                accent: accent,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return lang.getText(
                      'contact_section.form.message_error',
                      defaultValue: 'Please enter your message',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              // Status message
              AnimatedSwitcher(
                duration: AppDurations.medium,
                child: switch (_status) {
                  _FormStatus.success => Padding(
                    key: const ValueKey('success'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.expAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lang.getText(
                              'contact_section.form.success',
                              defaultValue:
                                  'Your email app is open. Review and send your message.',
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.expAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FormStatus.error => Padding(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.projAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lang.getText(
                              'contact_section.form.error',
                              defaultValue:
                                  'An error occurred. Please try again.',
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.projAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ => const SizedBox.shrink(key: ValueKey('idle')),
                },
              ),
              // Submit button
              _SubmitButton(
                accent: accent,
                label: lang.getText(
                  'contact_section.form.submit_button',
                  defaultValue: 'Send Message',
                ),
                isSending: _status == _FormStatus.sending,
                onTap: _status == _FormStatus.sending ? null : _submit,
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Transparent text field with accent-colored focus border.
class _CinematicTextField extends StatefulWidget {
  const _CinematicTextField({
    required this.controller,
    required this.label,
    required this.accent,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final Color accent;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<_CinematicTextField> createState() => _CinematicTextFieldState();
}

class _CinematicTextFieldState extends State<_CinematicTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
    child: AnimatedContainer(
      duration: AppDurations.buttonHover,
      curve: CinematicCurves.hoverLift,
      decoration: BoxDecoration(
        color: _focused
            ? widget.accent.withValues(alpha: 0.04)
            : AppColors.backgroundLight.withValues(alpha: 0.3),
        border: Border.all(
          color: _focused
              ? widget.accent.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        validator: widget.validator,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        style: AppTypography.body.copyWith(color: AppColors.textBright),
        cursorColor: widget.accent,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: AppTypography.bodySmall.copyWith(
            color: _focused ? widget.accent : AppColors.textSecondary,
          ),
          floatingLabelStyle: AppTypography.caption.copyWith(
            color: widget.accent,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: AppTypography.caption.copyWith(
            color: AppColors.projAccent,
          ),
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    ),
  );
}

/// Submit button with loading state.
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.accent,
    required this.label,
    required this.isSending,
    required this.onTap,
  });

  final Color accent;
  final String label;
  final bool isSending;
  final VoidCallback? onTap;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    cursor: widget.isSending
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: AppDurations.buttonHover,
        curve: CinematicCurves.hoverLift,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: widget.isSending
              ? widget.accent.withValues(alpha: 0.05)
              : _hovered
              ? widget.accent.withValues(alpha: 0.12)
              : widget.accent.withValues(alpha: 0.06),
          border: Border.all(
            color: _hovered && !widget.isSending
                ? widget.accent.withValues(alpha: 0.8)
                : widget.accent.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: _hovered && !widget.isSending
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: widget.isSending
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(widget.accent),
                ),
              )
            : Text(
                widget.label,
                style: AppFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.accent,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    ),
  );
}
