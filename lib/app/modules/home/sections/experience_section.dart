import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      constraints: BoxConstraints(minHeight: screenHeight - 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Obx(() {
              final isEnglish = languageController.currentLanguage == 'en';
              return ShimmeringText(
                text: isEnglish ? 'Experience' : 'Deneyim',
                baseColor: Colors.white,
                highlightColor: themeController.primaryColor,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
          ),

          const SizedBox(height: 60),

          // Deneyim Zaman Çizgisi
          Center(
            child: SizedBox(
              width: isMobile ? screenWidth * 0.9 : screenWidth * 0.7,
              child: Obx(() {
                final experiences =
                    languageController.cvData['experiences'] ?? [];

                return Column(
                  children: [
                    // Üst zaman çizgisi çubuğu
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeController.primaryColor.withOpacity(0.3),
                            themeController.primaryColor,
                            themeController.primaryColor.withOpacity(0.3),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),

                    // Deneyim kartları
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: experiences.length,
                      itemBuilder: (context, index) {
                        final experience = experiences[index];
                        // Sıraya göre yerleşim
                        final isEven = index % 2 == 0;

                        return _buildExperienceTimelineItem(
                          experience,
                          index,
                          isEven,
                          isMobile,
                          themeController,
                          languageController,
                        );
                      },
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Deneyim zaman çizgisi öğesi
  Widget _buildExperienceTimelineItem(
    Map<String, dynamic> experience,
    int index,
    bool isEven,
    bool isMobile,
    ThemeController themeController,
    LanguageController languageController,
  ) {
    final isEnglish = languageController.currentLanguage == 'en';

    // Mobil görünümde her zaman tek sütun
    if (isMobile) {
      return _buildMobileTimelineItem(
        experience,
        index,
        themeController,
        isEnglish,
      );
    }

    // Masaüstü görünümde alternatif yerleşim
    return _buildDesktopTimelineItem(
      experience,
      index,
      isEven,
      themeController,
      isEnglish,
    );
  }

  // Mobil için zaman çizgisi öğesi
  Widget _buildMobileTimelineItem(
    Map<String, dynamic> experience,
    int index,
    ThemeController themeController,
    bool isEnglish,
  ) {
    return Column(
      children: [
        // Zaman çizgisi noktası
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: themeController.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeController.primaryColor.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        // Dikey çizgi
        Container(
          width: 2,
          height: 30,
          color: themeController.primaryColor.withOpacity(0.5),
        ),

        // Deneyim kartı
        _buildExperienceCard(experience, themeController, isEnglish),

        // Alt dikey çizgi (son öğe değilse)
        if (index < 5) // Varsayılan olarak 5 deneyim olduğunu varsayıyorum
          Container(
            width: 2,
            height: 30,
            color: themeController.primaryColor.withOpacity(0.5),
          ),
      ],
    );
  }

  // Masaüstü için zaman çizgisi öğesi
  Widget _buildDesktopTimelineItem(
    Map<String, dynamic> experience,
    int index,
    bool isEven,
    ThemeController themeController,
    bool isEnglish,
  ) {
    return Row(
      children: [
        // Sol taraf (çift indeksli öğeler için içerik)
        Expanded(
          child:
              isEven
                  ? _buildExperienceCard(experience, themeController, isEnglish)
                  : const SizedBox.shrink(),
        ),

        // Orta nokta
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: themeController.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeController.primaryColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // Dikey çizgi
            if (index < 5) // Varsayılan olarak 5 deneyim olduğunu varsayıyorum
              Container(
                width: 2,
                height: 100,
                color: themeController.primaryColor.withOpacity(0.5),
              ),
          ],
        ),

        // Sağ taraf (tek indeksli öğeler için içerik)
        Expanded(
          child:
              !isEven
                  ? _buildExperienceCard(experience, themeController, isEnglish)
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Deneyim kartı
  Widget _buildExperienceCard(
    Map<String, dynamic> experience,
    ThemeController themeController,
    bool isEnglish,
  ) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(10),
      color: const Color(0xFF001628).withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: themeController.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Şirket adı
            Text(
              experience['company'] ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeController.primaryColor,
              ),
            ),

            const SizedBox(height: 5),

            // Pozisyon
            Text(
              isEnglish
                  ? experience['position'] ?? ''
                  : experience['position_tr'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 5),

            // Tarih aralığı
            Text(
              '${experience['start_date'] ?? ''} - ${experience['end_date'] ?? 'Present'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),

            const SizedBox(height: 15),

            // Açıklama
            Text(
              isEnglish
                  ? experience['description'] ?? ''
                  : experience['description_tr'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

            const SizedBox(height: 10),

            // Teknolojiler
            if (experience['technologies'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (experience['technologies'] as List).map((tech) {
                      return Chip(
                        label: Text(tech, style: const TextStyle(fontSize: 12)),
                        backgroundColor: themeController.primaryColor
                            .withOpacity(0.2),
                        side: BorderSide(
                          color: themeController.primaryColor.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// Parıldayan metin efekti
class ShimmeringText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

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
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
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
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              tileMode: TileMode.repeated,
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
