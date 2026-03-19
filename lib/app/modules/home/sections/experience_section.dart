import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/core/constants/app_colors.dart';
import 'package:flutter_web_portfolio/app/widgets/section_title.dart';

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
          Obx(() {
            final isEnglish = languageController.currentLanguage == 'en';
            return SectionTitle(title: isEnglish ? 'Experience' : 'Deneyim');
          }),

          const SizedBox(height: 60),

          Center(
            child: SizedBox(
              width: isMobile ? screenWidth * 0.9 : screenWidth * 0.7,
              child: Obx(() {
                final experiences =
                    languageController.cvData['experiences'] ?? [];

                return Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeController.primaryColor.withValues(alpha:0.3),
                            themeController.primaryColor,
                            themeController.primaryColor.withValues(alpha:0.3),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: experiences.length,
                      itemBuilder: (context, index) {
                        final experience = experiences[index];
                        final isEven = index % 2 == 0;

                        return _buildTimelineItem(
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

  Widget _buildTimelineItem(
    Map<String, dynamic> experience,
    int index,
    bool isEven,
    bool isMobile,
    ThemeController themeController,
    LanguageController languageController,
  ) {
    final isEnglish = languageController.currentLanguage == 'en';

    if (isMobile) {
      return _buildMobileItem(experience, index, themeController, isEnglish);
    }
    return _buildDesktopItem(experience, index, isEven, themeController, isEnglish);
  }

  Widget _buildMobileItem(
    Map<String, dynamic> experience,
    int index,
    ThemeController themeController,
    bool isEnglish,
  ) => Column(
      children: [
        _timelineDot(themeController),
        _timelineLine(themeController, height: 30),
        _experienceCard(experience, themeController, isEnglish),
        if (index < 5)
          _timelineLine(themeController, height: 30),
      ],
    );

  Widget _buildDesktopItem(
    Map<String, dynamic> experience,
    int index,
    bool isEven,
    ThemeController themeController,
    bool isEnglish,
  ) => Row(
      children: [
        Expanded(
          child: isEven
              ? _experienceCard(experience, themeController, isEnglish)
              : const SizedBox.shrink(),
        ),
        Column(
          children: [
            _timelineDot(themeController),
            if (index < 5) _timelineLine(themeController, height: 100),
          ],
        ),
        Expanded(
          child: !isEven
              ? _experienceCard(experience, themeController, isEnglish)
              : const SizedBox.shrink(),
        ),
      ],
    );

  Widget _timelineDot(ThemeController themeController) => _PulsingDot(
    color: themeController.primaryColor,
  );

  Widget _timelineLine(ThemeController themeController, {required double height}) =>
      Container(
        width: 2,
        height: height,
        color: themeController.primaryColor.withValues(alpha:0.5),
      );

  Widget _experienceCard(
    Map<String, dynamic> experience,
    ThemeController themeController,
    bool isEnglish,
  ) => Card(
      elevation: 5,
      margin: const EdgeInsets.all(10),
      color: AppColors.surface.withValues(alpha:0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: themeController.primaryColor.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience['company'] ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeController.primaryColor,
              ),
            ),
            const SizedBox(height: 5),
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
            Text(
              '${experience['start_date'] ?? ''} - ${experience['end_date'] ?? 'Present'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 15),
            Text(
              isEnglish
                  ? experience['description'] ?? ''
                  : experience['description_tr'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            if (experience['technologies'] != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (experience['technologies'] as List).map((tech) => Chip(
                    label: Text(tech, style: const TextStyle(fontSize: 12)),
                    backgroundColor: themeController.primaryColor.withValues(alpha:0.2),
                    side: BorderSide(
                      color: themeController.primaryColor.withValues(alpha:0.5),
                    ),
                  )).toList(),
              ),
          ],
        ),
      ),
    );
}

class ShimmeringText extends StatefulWidget {

  const ShimmeringText({
    super.key,
    required this.text,
    required this.baseColor,
    required this.highlightColor,
    required this.style,
  });
  final String text;
  final TextStyle style;
  final Color baseColor;
  final Color highlightColor;

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
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
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
            ).createShader(bounds),
          child: Text(widget.text, style: widget.style),
        ),
    );
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, __) => Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.3 + _controller.value * 0.4),
            blurRadius: 8 + _controller.value * 12,
            spreadRadius: 1 + _controller.value * 3,
          ),
        ],
      ),
    ),
  );
}
