import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/widgets/mouse_effects.dart';
import 'package:flutter_web_portfolio/app/controllers/shared_background_controller.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Tam ekran bir bölüm yaratacağız
    final galaxySize = math.min(screenWidth * 0.9, 900.0);
    final centralPlanetSize = galaxySize * 0.2; // Merkez gezegen boyutu

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      // Arka plan rengini kaldırıyoruz, genel arka plan home_view'den gelecek
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              child: Obx(() {
                final isEnglish = languageController.currentLanguage == 'en';
                return Text(
                  isEnglish ? 'Skills' : 'Beceriler',
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
                );
              }),
            ),
          ),

          // Galaksi görünümü
          SizedBox(
            width: galaxySize,
            height: galaxySize,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Obx(() {
                final skillsList =
                    languageController.cvData['skills'] as List<dynamic>? ?? [];
                return GalaxyView(
                  galaxySize: galaxySize,
                  centralPlanetSize: centralPlanetSize,
                  skillCategories: skillsList,
                );
              }),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class GalaxyView extends StatelessWidget {
  final double galaxySize;
  final double centralPlanetSize;
  final List<dynamic> skillCategories;

  const GalaxyView({
    Key? key,
    required this.galaxySize,
    required this.centralPlanetSize,
    required this.skillCategories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: galaxySize,
        height: galaxySize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka plandaki galaksi halkası
            Positioned.fill(
              child: CustomPaint(
                painter: GalaxyRingsPainter(galaxySize: galaxySize),
              ),
            ),

            // Merkez gezegen (ana mavi gezegen)
            Center(
              child: HoverAnimatedWidget(
                hoverScale: 1.05,
                child: Container(
                  width: centralPlanetSize,
                  height: centralPlanetSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue[400]!,
                        Colors.blue[400]!.withOpacity(0.7),
                        Colors.blue[400]!.withOpacity(0.3),
                      ],
                      stops: const [0.2, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[400]!.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.code,
                      size: centralPlanetSize * 0.5,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),

            // Dönen gezegenler (beceriler)
            ...generateOrbitingPlanets(),
          ],
        ),
      ),
    );
  }

  // Tüm beceri türlerinden önemli becerileri seç - sadece ana teknolojileri alır
  List<Map<String, dynamic>> _extractMainSkills() {
    final List<Map<String, dynamic>> mainSkills = [];

    try {
      // Kategoriler ve renkler için eşleştirme
      final Map<String, Color> categoryColors = {
        'Mobile': Colors.blue[400]!,
        'Frontend': Colors.orange[400]!,
        'Backend': Colors.green[500]!,
        'DevOps': Colors.purple[400]!,
        'Database': Colors.teal[400]!,
      };

      // JSON'dan verileri al
      for (final skillCategory in skillCategories) {
        final String category = skillCategory['category'] ?? '';
        final List<dynamic> items = skillCategory['items'] ?? [];

        // Her kategoriden en fazla 4 beceri al (galaksi görünümünü aşırı doldurmamak için)
        final int maxItemsPerCategory = 4;
        final int itemsToTake = math.min(items.length, maxItemsPerCategory);

        for (int i = 0; i < itemsToTake; i++) {
          final skill = items[i];
          if (skill is String) {
            mainSkills.add({
              "name": skill,
              "category": category,
              "color": categoryColors[category] ?? Colors.grey[400]!,
            });
          }
        }
      }

      // En fazla 12 beceri göster
      if (mainSkills.length > 12) {
        mainSkills.shuffle(); // Rastgele bir seçim yap
        return mainSkills.sublist(0, 12);
      }
    } catch (e) {
      debugPrint('Error extracting skills: $e');
      // Hata durumunda fallback olarak sabit becerileri göster
      return [
        {"name": "Flutter", "category": "Mobile", "color": Colors.blue[400]!},
        {"name": "React", "category": "Frontend", "color": Colors.orange[400]!},
        {"name": "Node.js", "category": "Backend", "color": Colors.green[500]!},
        {
          "name": "JavaScript",
          "category": "Frontend",
          "color": Colors.orange[400]!,
        },
        {"name": "HTML", "category": "Frontend", "color": Colors.orange[400]!},
        {"name": "CSS", "category": "Frontend", "color": Colors.orange[400]!},
      ];
    }

    return mainSkills;
  }

  List<Widget> generateOrbitingPlanets() {
    final List<Widget> planets = [];
    final skills = _extractMainSkills();
    final int skillCount = skills.length;

    if (skillCount == 0) return planets;

    for (int i = 0; i < skillCount; i++) {
      final skill = skills[i];
      final String skillName = skill['name'] as String;
      final Color skillColor = skill['color'] as Color;

      // Her beceri için eşit aralıklı açı
      final double angle = 2 * math.pi * i / skillCount;
      final double orbitRadius = galaxySize * 0.35; // Yörünge yarıçapı
      final double planetSize = galaxySize * 0.08;

      // Yörüngedeki gezegen konumu
      planets.add(
        AnimatedBuilder(
          animation:
              SharedBackgroundController.animationController ??
              const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            // Farklı hızlar için ekstra çarpan
            final speedMultiplier = 1.0 + (i % 3) * 0.15;
            final animValue =
                SharedBackgroundController.animationController?.value ?? 0.0;
            final double rotationAngle =
                angle + (animValue * 2 * math.pi * speedMultiplier);

            return Positioned(
              left:
                  galaxySize / 2 +
                  orbitRadius * math.cos(rotationAngle) -
                  planetSize / 2,
              top:
                  galaxySize / 2 +
                  orbitRadius * math.sin(rotationAngle) -
                  planetSize / 2,
              child: HoverAnimatedWidget(
                hoverScale: 1.2,
                child: Container(
                  width: planetSize,
                  height: planetSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: skillColor,
                    boxShadow: [
                      BoxShadow(
                        color: skillColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Tooltip(
                      message: skillName,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSkillIcon(skillName, planetSize * 0.4),
                          const SizedBox(height: 2),
                          Text(
                            _getSkillDisplayName(skillName),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: planetSize * 0.18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return planets;
  }

  // PNG ikon widget'ı oluştur
  Widget _buildSkillIcon(String skillName, double size) {
    final iconPath = _getSkillIconPath(skillName);

    if (iconPath.isEmpty) {
      return _buildFallbackIcon(skillName, size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Hata durumunda log yazdır ve fallback ikonu göster
          debugPrint('Failed to load icon: $iconPath - Error: $error');

          // Bazı özel durumlar için alternatif ikonlar deneyelim
          if (iconPath.contains('skills/')) {
            final String basePath = 'assets/icons/';
            final String fileName = iconPath.split('/').last;

            // Genel ikonlar klasöründe aynı isimli dosya var mı deneyelim
            return Image.asset(
              '$basePath$fileName',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Yine başarısız olursa fallback ikonu göster
                return _buildFallbackIcon(skillName, size);
              },
            );
          }

          return _buildFallbackIcon(skillName, size);
        },
      ),
    );
  }

  // Beceri için görüntülenecek kısa isim - kısaltma gerekirse
  String _getSkillDisplayName(String skill) {
    // Kısaltmalar için Map kullanıyoruz
    final Map<String, String> shortNames = {
      "JavaScript": "JS",
      "TypeScript": "TS",
      "Express.js": "Express",
      "RESTful API": "REST API",
    };

    // Map'te varsa kısaltmayı döndür, yoksa orijinal ismi kullan
    return shortNames[skill] ?? skill;
  }

  // Beceriye uygun PNG ikon yolunu ver
  String _getSkillIconPath(String skill) {
    // Beceri isimlerini küçük harfe çevirip boşlukları ve özel karakterleri kaldır
    final String normalizedSkill = skill
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll(',', '');

    // Özel durumlar için map kullanıyoruz
    final Map<String, String> specialCases = {
      "nodejs": "nodejs",
      "expressjs": "express",
      "javascript": "javascript",
      "typescript": "typescript",
      "html": "html5",
      "css": "css3",
      "mongodb": "mongodb",
      "mssql": "mssql",
      "sqlite": "sqlite",
      "aws": "aws",
      "awss3bucket": "aws", // AWS S3 Bucket için AWS ikonu kullan
      "react": "react",
      "flutter": "flutter",
      "restfulapi": "api", // RESTful API için genel API ikonu
      "websocket": "websocket",
      "statemanagementgetxproviderbloc":
          "flutter", // State management için Flutter ikonu
    };

    // Özel durumlar var mı kontrol et
    String iconName = specialCases[normalizedSkill] ?? normalizedSkill;

    // Dosya yolunu oluştur
    final String iconPath = 'assets/icons/skills/$iconName.png';

    return iconPath;
  }

  // Fallback ikon
  Widget _buildFallbackIcon(String skillName, double size) {
    // Beceri adına göre renk belirle
    final Color iconColor = _getSkillColor(skillName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          skillName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  // Beceri için renk belirle
  Color _getSkillColor(String skill) {
    final String normalizedSkill = skill.toLowerCase();

    // Kategorilere göre renkler
    if (normalizedSkill.contains('flutter') ||
        normalizedSkill.contains('mobile') ||
        normalizedSkill.contains('android') ||
        normalizedSkill.contains('ios')) {
      return Colors.blue[400]!;
    } else if (normalizedSkill.contains('node') ||
        normalizedSkill.contains('express') ||
        normalizedSkill.contains('api') ||
        normalizedSkill.contains('rest')) {
      return Colors.green[500]!;
    } else if (normalizedSkill.contains('react') ||
        normalizedSkill.contains('javascript') ||
        normalizedSkill.contains('html') ||
        normalizedSkill.contains('css')) {
      return Colors.orange[400]!;
    } else if (normalizedSkill.contains('aws') ||
        normalizedSkill.contains('docker') ||
        normalizedSkill.contains('git')) {
      return Colors.purple[400]!;
    } else if (normalizedSkill.contains('sql') ||
        normalizedSkill.contains('mongo') ||
        normalizedSkill.contains('database')) {
      return Colors.teal[400]!;
    }

    // Varsayılan renk
    return Colors.blue[300]!;
  }

  // Kategori renklerini elde et
  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue[400]!, // Mobile
      Colors.green[500]!, // Backend
      Colors.orange[400]!, // Frontend
      Colors.purple[400]!, // DevOps
      Colors.teal[400]!, // Database
    ];

    return colors[index % colors.length];
  }
}

// Galaksi halkalarını çizen özel painter
class GalaxyRingsPainter extends CustomPainter {
  final double galaxySize;

  const GalaxyRingsPainter({required this.galaxySize});

  @override
  void paint(Canvas canvas, Size size) {
    // Arkadaki parıltılı galaksi efekti
    final Paint galaxyPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.blue[400]!.withOpacity(0.2),
              Colors.blue[400]!.withOpacity(0.1),
              Colors.blue[400]!.withOpacity(0.05),
              Colors.transparent,
            ],
            stops: const [0.2, 0.5, 0.8, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: galaxySize / 2,
            ),
          );

    // Galaksiyi çiz
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      galaxySize / 2,
      galaxyPaint,
    );

    // Yörüngeler - skill'lerin bulunduğu ana yörünge daha belirgin
    final double mainOrbitRadius = galaxySize * 0.35;
    final Paint mainOrbitPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.blue[400]!.withOpacity(0.5);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      mainOrbitRadius,
      mainOrbitPaint,
    );

    // Diğer dekoratif halkalar
    for (int i = 0; i < 4; i++) {
      // Ana yörünge dışında 4 farklı halka çiz
      double radius;
      if (i < 2) {
        // İç halkalar
        radius = galaxySize * (0.15 + i * 0.1);
      } else {
        // Dış halkalar
        radius = galaxySize * (0.45 + (i - 2) * 0.08);
      }

      // Ana yörüngeyi tekrar çizme
      if ((radius - mainOrbitRadius).abs() < 0.01) continue;

      final Paint ringPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.blue[400]!.withOpacity(0.2 - i * 0.03);

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        ringPaint,
      );
    }

    // Yıldızlar
    final random = math.Random(42); // Sabit seed
    for (int i = 0; i < 200; i++) {
      final double starX = random.nextDouble() * size.width;
      final double starY = random.nextDouble() * size.height;
      final double starSize = random.nextDouble() * 1.8 + 0.5;

      final Paint starPaint =
          Paint()
            ..color = Colors.white.withOpacity(random.nextDouble() * 0.6 + 0.3);

      canvas.drawCircle(Offset(starX, starY), starSize, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
