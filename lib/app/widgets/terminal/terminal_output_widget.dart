import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/models/terminal_output_model.dart';

/// Terminal çıktılarını gösteren widget
class TerminalOutputWidget extends StatelessWidget {
  /// Gösterilecek terminal çıktısı
  final TerminalOutputModel output;

  /// Terminal komut öneki ('>' gibi)
  final String terminalPrefix;

  const TerminalOutputWidget({
    super.key,
    required this.output,
    this.terminalPrefix = '>',
  });

  @override
  Widget build(BuildContext context) {
    // Komut çıktısı ise özel gösterim
    if (output.type == TerminalOutputType.command) {
      return _buildCommandOutput();
    }

    // Normal çıktı gösterimi
    return output.content.isEmpty
        ? const SizedBox(height: 8)
        : Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: InkWell(
            onTap: output.onTap,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                output.content,
                style: TextStyle(
                  color: output.color,
                  fontFamily: 'RobotoMono',
                  fontSize: 14,
                  height: 1.5,
                  fontWeight:
                      output.isBold ? FontWeight.bold : FontWeight.normal,
                  decoration:
                      output.onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        );
  }

  /// Komut çıktısını özel olarak gösterir
  Widget _buildCommandOutput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$terminalPrefix ',
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontFamily: 'RobotoMono',
              fontSize: 14,
              height: 1.5,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                output.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
