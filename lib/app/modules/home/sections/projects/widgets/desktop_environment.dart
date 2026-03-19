import 'package:flutter/material.dart';

/// Desktop background widget.
/// Renders a fully transparent gradient so the CosmicBackground behind it
/// remains visible.
class DesktopBackground extends StatelessWidget {
  final int currentIndex;

  const DesktopBackground({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Colors.transparent, // Fully transparent so CosmicBackground shows
            Colors.transparent, // Fully transparent so CosmicBackground shows
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// A single desktop icon that can be tapped or double-tapped to open.
class DesktopIcon extends StatelessWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  const DesktopIcon({
    super.key,
    required this.title,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onTap, // Usually desktop icons are opened with double-click
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 80,
        child: Column(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
