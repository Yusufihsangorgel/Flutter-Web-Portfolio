import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({Key? key}) : super(key: key);

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Form controller'ları
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  // Form alanları için fokus düğümleri
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  // Geçerli odaklı alan
  int _focusedField = -1;

  // Gönderim durumu
  final RxBool _isSubmitting = false.obs;
  final RxBool _isSubmitted = false.obs;

  // Fare pozisyonu kullanmak için SharedBackgroundController

  @override
  void initState() {
    super.initState();

    // Fokus değişimlerini dinle
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
    // Controller'ları temizle
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();

    super.dispose();
  }

  // Form gönderimi
  void _submitForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _messageController.text.isEmpty) {
      // Boş alan kontrolü
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

    // Burada gerçek form gönderimi yapılacak
    // Şimdilik bir gecikme simülasyonu
    Future.delayed(const Duration(seconds: 2), () {
      _isSubmitting.value = false;
      _isSubmitted.value = true;

      // Form temizleme
      _nameController.clear();
      _emailController.clear();
      _messageController.clear();

      // Focus temizleme
      _focusedField = -1;
      FocusScope.of(context).unfocus();

      // 3 saniye sonra başarı mesajını kapat
      Future.delayed(const Duration(seconds: 3), () {
        _isSubmitted.value = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MouseRegion(
      onHover: (event) {
        // Fare pozisyonunu güncellemek için SharedBackgroundController'ı kullan
        SharedBackgroundController.updateMousePosition(event.localPosition);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 100,
          horizontal: screenWidth > 800 ? 100 : 30,
        ),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 80,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Obx(() {
                final isEnglish = languageController.currentLanguage == 'en';
                return ShimmeringText(
                  text: isEnglish ? 'Contact Me' : 'İletişim',
                  baseColor: Colors.white,
                  highlightColor: themeController.primaryColor,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                );
              }),
            ),

            const SizedBox(height: 40),

            // İletişim formu ve bilgileri
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İletişim formu
                    Expanded(
                      flex: 3,
                      child: FadeInLeft(
                        duration: const Duration(milliseconds: 800),
                        child: _buildContactForm(screenWidth > 800),
                      ),
                    ),

                    if (screenWidth > 800) ...[
                      const SizedBox(width: 40),

                      // İletişim bilgileri
                      Expanded(
                        flex: 2,
                        child: FadeInRight(
                          duration: const Duration(milliseconds: 800),
                          child: _buildContactInfo(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Mobilde iletişim bilgileri
            if (screenWidth <= 800) ...[
              const SizedBox(height: 40),
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: _buildContactInfo(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // İletişim formu
  Widget _buildContactForm(bool isMobile) {
    return HolographicContainer(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Obx(() {
          if (_isSubmitted.value) {
            return _buildSuccessMessage();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form başlığı
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

              // İsim alanı
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

              // E-posta alanı
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

              // Mesaj alanı
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

              // Gönder butonu
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
  }

  // Başarılı mesaj
  Widget _buildSuccessMessage() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Başarı ikonu
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 50),
            ),

            const SizedBox(height: 20),

            // Başarı mesajı
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

            // Alt mesaj
            Text(
              languageController.currentLanguage == 'en'
                  ? 'I will get back to you soon.'
                  : 'En kısa sürede size dönüş yapacağım.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // İletişim bilgileri
  Widget _buildContactInfo() {
    return HolographicContainer(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Obx(() {
          final data = languageController.cvData;
          final isEnglish = languageController.currentLanguage == 'en';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bölüm başlığı
              Text(
                isEnglish ? 'Contact Information' : 'İletişim Bilgileri',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // İletişim bilgileri listesi
              _buildContactInfoItem(
                Icons.email,
                isEnglish ? 'Email' : 'E-posta',
                data['email'] ?? '',
              ),

              const SizedBox(height: 16),

              _buildContactInfoItem(
                Icons.phone,
                isEnglish ? 'Phone' : 'Telefon',
                data['phone'] ?? '',
              ),

              const SizedBox(height: 16),

              _buildContactInfoItem(
                Icons.location_on,
                isEnglish ? 'Location' : 'Konum',
                data['location'] ?? '',
              ),

              const SizedBox(height: 30),

              // Sosyal medya
              Text(
                isEnglish ? 'Find Me On' : 'Sosyal Medya',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Sosyal medya butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSocialButton(Icons.language, 'Website', () {}),
                  const SizedBox(width: 12),
                  _buildSocialButton(Icons.code, 'GitHub', () {}),
                  const SizedBox(width: 12),
                  _buildSocialButton(Icons.link, 'LinkedIn', () {}),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // Holografik text field
  Widget _buildHolographicTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData prefixIcon,
    bool isActive = false,
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            isActive
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isActive
                  ? themeController.primaryColor
                  : Colors.white.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: themeController.primaryColor.withOpacity(0.5),
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
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
                    : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  // İletişim bilgi öğesi
  Widget _buildContactInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: themeController.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: themeController.primaryColor),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sosyal medya butonu
  Widget _buildSocialButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return HoverAnimatedWidget(
      hoverScale: 1.1,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// Holografik Arka Plan
class HolographicBackground extends StatelessWidget {
  final Color baseColor;

  const HolographicBackground({Key? key, required this.baseColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient arka plan
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF0A0A1E), const Color(0xFF070720)],
            ),
          ),
        ),

        // Holografik ızgara
        CustomPaint(painter: HolographicGridPainter(baseColor: baseColor)),

        // Holografik parçacıklar
        CustomPaint(painter: HolographicParticlesPainter(baseColor: baseColor)),
      ],
    );
  }
}

// Holografik Izgara Painter
class HolographicGridPainter extends CustomPainter {
  final Color baseColor;

  HolographicGridPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Izgara çizgileri
    final gridSize = 40.0;
    final maxDistance =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Yatay çizgiler
    for (double y = 0; y < size.height; y += gridSize) {
      final distanceRatio = 1 - ((y - center.dy).abs() / (size.height / 2));

      paint.color = baseColor.withOpacity(
        0.1 + (distanceRatio * 0.2) + (math.sin(math.pi + y * 0.01) * 0.05),
      );

      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dikey çizgiler
    for (double x = 0; x < size.width; x += gridSize) {
      final distanceRatio = 1 - ((x - center.dx).abs() / (size.width / 2));

      paint.color = baseColor.withOpacity(
        0.1 + (distanceRatio * 0.2) + (math.sin(math.pi + x * 0.01) * 0.05),
      );

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicGridPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}

// Holografik Parçacıklar Painter
class HolographicParticlesPainter extends CustomPainter {
  final Color baseColor;

  HolographicParticlesPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Sabit tohum değeri
    final particleCount = 100;

    for (int i = 0; i < particleCount; i++) {
      // Her parçacık için rastgele pozisyon ve boyut
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final particleSize = 1.0 + (random.nextDouble() * 3.0);

      // Animasyon için kaydırma
      final xOffset = math.sin(math.pi + i * 0.1) * 5.0;
      final yOffset = math.cos(math.pi + i * 0.1) * 5.0;

      // Parçacık opaklığı (yanıp sönme efekti)
      final opacity = 0.3 + (math.sin(math.pi + i * 0.2) * 0.2);

      final paint =
          Paint()
            ..color = baseColor.withOpacity(opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x + xOffset, y + yOffset), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HolographicParticlesPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor;
  }
}

// Holografik Container
class HolographicContainer extends StatelessWidget {
  final Widget child;

  const HolographicContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

// Holografik Buton
class HolographicButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const HolographicButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  State<HolographicButton> createState() => _HolographicButtonState();
}

class _HolographicButtonState extends State<HolographicButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color:
                _isHovered
                    ? themeController.primaryColor
                    : themeController.primaryColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            boxShadow:
                _isHovered
                    ? [
                      BoxShadow(
                        color: themeController.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Parlayan metin
class ShimmeringText extends StatefulWidget {
  final String text;
  final Color baseColor;
  final Color highlightColor;
  final TextStyle style;

  const ShimmeringText({
    Key? key,
    required this.text,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
  }) : super(key: key);

  @override
  State<ShimmeringText> createState() => _ShimmeringTextState();
}

class _ShimmeringTextState extends State<ShimmeringText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: _SlidingGradientTransform(
                slidePercent: _shimmerController.value,
              ),
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

// Shader transformasyonu
class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 3 - 1.0),
      0.0,
      0.0,
    );
  }
}
