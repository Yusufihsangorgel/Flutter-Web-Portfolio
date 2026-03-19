import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'holographic_painters.dart';

/// Contact Form
///
/// A stateful form widget containing name, email, and message fields with
/// holographic styling. Handles form validation, submission simulation,
/// and displays a success message after sending.
class ContactForm extends StatefulWidget {

  const ContactForm({super.key, required this.isWideLayout});
  final bool isWideLayout;

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Focus nodes for form fields
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  // Currently focused field index
  int _focusedField = -1;

  // Submission state
  final RxBool _isSubmitting = false.obs;
  final RxBool _isSubmitted = false.obs;

  @override
  void initState() {
    super.initState();

    // Listen for focus changes
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) setState(() => _focusedField = 0);
    });
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) setState(() => _focusedField = 1);
    });
    _messageFocus.addListener(() {
      if (_messageFocus.hasFocus) setState(() => _focusedField = 2);
    });
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();

    super.dispose();
  }

  // Form submission
  void _submitForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      // Empty field check
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isSubmitting.value = true;

    // Actual form submission would go here.
    // For now, simulate a delay.
    Future.delayed(const Duration(seconds: 2), () {
      _isSubmitting.value = false;
      _isSubmitted.value = true;

      // Clear the form
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();

      // Clear focus
      _focusedField = -1;
      FocusScope.of(context).unfocus();

      // Hide the success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _isSubmitted.value = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) => HolographicContainer(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Obx(() {
          if (_isSubmitted.value) {
            return _buildSuccessMessage();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Text(
                languageController.currentLanguage == 'en'
                    ? 'Send Message'
                    : 'Mesaj Gönder',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Name field
              _buildHolographicTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                hintText:
                    languageController.currentLanguage == 'en'
                        ? 'Your Name'
                        : 'Adınız',
                prefixIcon: Icons.person,
                isActive: _focusedField == 0,
              ),

              const SizedBox(height: 20),

              // Email field
              _buildHolographicTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                hintText:
                    languageController.currentLanguage == 'en'
                        ? 'Your Email'
                        : 'E-posta Adresiniz',
                prefixIcon: Icons.email,
                isActive: _focusedField == 1,
              ),

              const SizedBox(height: 20),

              // Message field
              _buildHolographicTextField(
                controller: _messageController,
                focusNode: _messageFocus,
                hintText:
                    languageController.currentLanguage == 'en'
                        ? 'Your Message'
                        : 'Mesajınız',
                prefixIcon: Icons.message,
                isActive: _focusedField == 2,
                maxLines: 5,
              ),

              const SizedBox(height: 30),

              // Submit button
              Align(
                alignment: Alignment.centerRight,
                child: HolographicButton(
                  onPressed: _isSubmitting.value ? null : _submitForm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child:
                        _isSubmitting.value
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              languageController.currentLanguage == 'en'
                                  ? 'Send Message'
                                  : 'Mesaj Gönder',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );

  // Success message displayed after form submission
  Widget _buildSuccessMessage() => SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha:0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 50),
            ),

            const SizedBox(height: 20),

            // Success message
            Text(
              languageController.currentLanguage == 'en'
                  ? 'Message Sent Successfully!'
                  : 'Mesajınız Başarıyla Gönderildi!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              languageController.currentLanguage == 'en'
                  ? 'I will get back to you soon.'
                  : 'En kısa sürede size dönüş yapacağım.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha:0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  // Holographic styled text field
  Widget _buildHolographicTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool isActive = false,
    int maxLines = 1,
  }) => AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            isActive
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive
                  ? themeController.primaryColor
                  : Colors.white.withValues(alpha:0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: themeController.primaryColor.withValues(alpha:0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
                : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha:0.5)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            prefixIcon,
            color:
                isActive
                    ? themeController.primaryColor
                    : Colors.white.withValues(alpha:0.5),
          ),
        ),
      ),
    );
}
