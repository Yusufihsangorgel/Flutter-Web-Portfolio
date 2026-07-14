import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_web_portfolio/app/controllers/cursor_controller.dart';

void main() {
  late CursorController controller;

  setUp(() {
    controller = CursorController();
    addTearDown(controller.close);
  });

  group('CursorController', () {
    test('starts with a neutral cursor state', () {
      expect(controller.state.isHovering, isFalse);
      expect(controller.state.hoverAccent, isNull);
    });

    test('publishes hover transitions as immutable state', () async {
      final emitted = <CursorUiState>[];
      final subscription = controller.stream.listen(emitted.add);
      addTearDown(subscription.cancel);

      controller
        ..setHovering(true)
        ..setHovering(false);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.map((state) => state.isHovering), [isTrue, isFalse]);
    });

    test('sets, replaces and clears the hover accent', () {
      controller.setHoverAccent(Colors.red);
      expect(controller.state.hoverAccent, Colors.red);

      controller.setHoverAccent(Colors.blue);
      expect(controller.state.hoverAccent, Colors.blue);

      controller.setHoverAccent(null);
      expect(controller.state.hoverAccent, isNull);
    });

    test('does not emit duplicate snapshots', () async {
      controller.setHovering(true);
      final emissions = <CursorUiState>[];
      final subscription = controller.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      controller.setHovering(true);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isEmpty);
    });
  });
}
