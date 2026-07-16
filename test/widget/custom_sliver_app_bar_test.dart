import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/widgets/custom_sliver_app_bar.dart';

void main() {
  test('anchors reading progress to the writing-direction origin', () {
    const size = Size(1000, 1);

    expect(
      SceneProgressGeometry.bounds(
        size: size,
        progress: 0.35,
        textDirection: TextDirection.ltr,
      ),
      const Rect.fromLTWH(0, 0, 350, 1),
    );
    expect(
      SceneProgressGeometry.bounds(
        size: size,
        progress: 0.35,
        textDirection: TextDirection.rtl,
      ),
      const Rect.fromLTWH(650, 0, 350, 1),
    );
  });

  test('clamps progress geometry to the available width', () {
    const size = Size(800, 1);

    expect(
      SceneProgressGeometry.bounds(
        size: size,
        progress: -1,
        textDirection: TextDirection.rtl,
      ),
      const Rect.fromLTWH(800, 0, 0, 1),
    );
    expect(
      SceneProgressGeometry.bounds(
        size: size,
        progress: 2,
        textDirection: TextDirection.rtl,
      ),
      const Rect.fromLTWH(0, 0, 800, 1),
    );
  });
}
