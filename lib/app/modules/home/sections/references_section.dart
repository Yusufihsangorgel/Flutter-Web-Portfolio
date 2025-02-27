import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_web_portfolio/app/controllers/language_controller.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';

class ReferencesSection extends StatefulWidget {
  const ReferencesSection({super.key});

  @override
  State<ReferencesSection> createState() => _ReferencesSectionState();
}

class _ReferencesSectionState extends State<ReferencesSection> {
  final LanguageController languageController = Get.find<LanguageController>();
  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 800;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Obx(() {
              final isEnglish = languageController.currentLanguage == 'en';
              return Text(
                isEnglish ? 'References' : 'Referanslar',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: themeController.primaryColor,
                ),
              );
            }),
          ),

          const SizedBox(height: 40),

          // Referanslar
          Obx(() {
            final references = languageController.cvData['references'] ?? [];

            return isSmallScreen
                ? _buildMobileReferences(references)
                : _buildDesktopReferences(references);
          }),
        ],
      ),
    );
  }

  // Mobil görünüm - dikey liste
  Widget _buildMobileReferences(List<dynamic> references) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: references.length,
      itemBuilder: (context, index) {
        final reference = references[index];

        return FadeInLeft(
          duration: Duration(milliseconds: 600 + (index * 100)),
          child: _buildReferenceCard(reference, index),
        );
      },
    );
  }

  // Masaüstü görünüm - yatay kaydırılabilir liste
  Widget _buildDesktopReferences(List<dynamic> references) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: references.length,
        itemBuilder: (context, index) {
          final reference = references[index];

          return FadeInUp(
            duration: Duration(milliseconds: 600 + (index * 100)),
            child: Container(
              width: 350,
              margin: const EdgeInsets.only(right: 20),
              child: _buildReferenceCard(reference, index),
            ),
          );
        },
      ),
    );
  }

  // Referans kartı
  Widget _buildReferenceCard(Map<String, dynamic> reference, int index) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Referans kişi bilgileri
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getAvatarColor(index),
                  child: Text(
                    _getInitials(reference['name'] ?? ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // İsim ve pozisyon
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reference['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        reference['position'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              themeController.isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Text(
                        reference['company'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              themeController.isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Alıntı işareti
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.format_quote,
                size: 30,
                color: themeController.primaryColor.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 8),

            // Referans metni
            Expanded(
              child: Text(
                reference['text'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color:
                      themeController.isDarkMode
                          ? Colors.white70
                          : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 6,
              ),
            ),

            // İletişim bilgileri
            if (reference.containsKey('email') ||
                reference.containsKey('phone'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reference.containsKey('email'))
                      Tooltip(
                        message: reference['email'],
                        child: Icon(
                          Icons.email,
                          size: 20,
                          color: themeController.primaryColor,
                        ),
                      ),

                    if (reference.containsKey('email') &&
                        reference.containsKey('phone'))
                      const SizedBox(width: 12),

                    if (reference.containsKey('phone'))
                      Tooltip(
                        message: reference['phone'],
                        child: Icon(
                          Icons.phone,
                          size: 20,
                          color: themeController.primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // İsmin baş harflerini al
  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else if (nameParts.length == 1) {
      return nameParts[0][0];
    }

    return '';
  }

  // Avatar rengi
  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue[700]!,
      Colors.purple[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
    ];

    return colors[index % colors.length];
  }
}
