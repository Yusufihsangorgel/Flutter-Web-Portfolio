import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/controllers/theme_controller.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';
import 'package:flutter_web_portfolio/app/widgets/terminal/terminal_output_widget.dart';
import 'package:get/get.dart';

/// Widget that displays the terminal screen
class TerminalWidget extends StatelessWidget {

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
  final List<TerminalOutputModel> outputs;
  final ScrollController scrollController;
  final String title;
  final String terminalPrefix;
  final TextEditingController commandController;
  final FocusNode terminalFocus;
  final Function(String) onSubmitCommand;

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        color:
            themeController.isDarkMode
                ? Colors.black.withValues(alpha:0.8)
                : Colors.black87,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color:
              themeController.isDarkMode
                  ? Colors.white.withValues(alpha:0.1)
                  : Colors.black.withValues(alpha:0.2),
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

  /// Builds the terminal title bar
  Widget _buildTerminalHeader() => Container(
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
          // Traffic light buttons
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
                  color: Colors.white.withValues(alpha:0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );

  /// Builds the terminal content area
  Widget _buildTerminalContent() => GestureDetector(
      onTap: terminalFocus.requestFocus,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...outputs.map((output) {
                if (output.isTyping) {
                  // Show only the visible portion while animation is in progress
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
              }),

              // Active command input
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
