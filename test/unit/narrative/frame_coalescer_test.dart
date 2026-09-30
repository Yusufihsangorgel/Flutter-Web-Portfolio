import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_portfolio/app/narrative/rendering/frame_coalescer.dart';

final class _TestFrame extends FrameCoalescer {
  int value = 0;
  int? pending;

  void queue(int next) {
    pending = next;
    scheduleFrameUpdate(() {
      final next = pending;
      pending = null;
      if (next == null || next == value) return false;
      value = next;
      return true;
    });
  }
}

void main() {
  testWidgets('coalesces updates and ignores disposed frames', (tester) async {
    var notifications = 0;
    final frame = _TestFrame()
      ..addListener(() => notifications += 1)
      ..queue(1)
      ..queue(2);
    await tester.pump();
    expect(frame.value, 2);
    expect(notifications, 1);

    frame.queue(2);
    await tester.pump();
    expect(notifications, 1);

    frame
      ..queue(3)
      ..dispose();
    await tester.pump();
    expect(notifications, 1);
  });
}
