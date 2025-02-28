import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';
import 'package:flutter_web_portfolio/app/widgets/terminal/terminal_output_widget.dart';
import 'package:get/get.dart';

/// Terminal ekranını gösteren widget
class TerminalWidget extends StatelessWidget {
  /// Terminal çıktıları
  final List<TerminalOutputModel> outputs;

  /// ScrollController for auto-scrolling
  final ScrollController scrollController;

  /// Terminal ekranının başlığı
  final String title;

  /// Terminal komut öneki
  final String terminalPrefix;

  /// Aktif komut için TextEditingController
  final TextEditingController commandController;

  /// Terminal girişi için FocusNode
  final FocusNode terminalFocus;

  /// Komut çalıştırma fonksiyonu
  final Function(String) onSubmitCommand;

  const TerminalWidget({
    super.key,
    required this.outputs,
    required this.scrollController,
    required this.title,
    required this.terminalPrefix,
    required this.commandController,
    required this.terminalFocus,
    required this.onSubmitCommand,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color:
            themeController.isDarkMode
                ? Colors.black.withOpacity(0.8)
                : Colors.black87,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color:
              themeController.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTerminalHeader(),
          Expanded(child: _buildTerminalContent()),
        ],
      ),
    );
  }

  /// Terminal başlığını oluşturur
  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            Get.find<ThemeController>().isDarkMode
                ? Colors.grey.shade900
                : Colors.grey.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          // Terminal kontrol butonları
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.yellow,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Sağa boşluk
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  /// Terminal içeriğini oluşturur
  Widget _buildTerminalContent() {
    return GestureDetector(
      onTap: () => terminalFocus.requestFocus(),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: // Terminal çıktıları
            SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Önceki çıktılar
              ...outputs.map((output) {
                if (output.isTyping) {
                  // Animasyon devam ederken sadece görünen kısmı göster
                  final visibleContent = output.content.substring(
                    0,
                    output.currentIndex,
                  );
                  return TerminalOutputWidget(
                    output: TerminalOutputModel(
                      content: visibleContent,
                      type: output.type,
                      color: output.color,
                      isBold: output.isBold,
                      onTap: output.onTap,
                      isTyping: true,
                      isCompleted: false,
                      currentIndex: output.currentIndex,
                    ),
                    terminalPrefix: terminalPrefix,
                  );
                } else {
                  return TerminalOutputWidget(
                    output: output,
                    terminalPrefix: terminalPrefix,
                  );
                }
              }).toList(),

              // Aktif komut girişi
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    terminalPrefix,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      color: Colors.cyanAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: commandController,
                      focusNode: terminalFocus,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      cursorColor: Colors.white,
                      cursorWidth: 5,
                      cursorRadius: const Radius.circular(2),
                      showCursor: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onSubmitted: onSubmitCommand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
