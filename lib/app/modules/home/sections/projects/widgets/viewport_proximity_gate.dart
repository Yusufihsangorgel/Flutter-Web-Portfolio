import 'package:flutter/widgets.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/atlas_style.dart';

/// Shows [placeholder] until this subtree comes within [lead] viewport extents
/// of the enclosing scroll view, then builds [builder] once and keeps it.
///
/// Without an enclosing [Scrollable] the child is built immediately.
final class ViewportProximityGate extends StatefulWidget {
  const ViewportProximityGate({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox.expand(),
    this.lead = AtlasLayout.lazyLoadLead,
  });

  final WidgetBuilder builder;
  final Widget placeholder;
  final double lead;

  @override
  State<ViewportProximityGate> createState() => _ViewportProximityGateState();
}

final class _ViewportProximityGateState extends State<ViewportProximityGate> {
  ScrollableState? _scrollable;
  bool _near = false;
  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_near) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _detach();
      _near = true;
    } else if (!identical(scrollable, _scrollable)) {
      _detach();
      _scrollable = scrollable..position.addListener(_check);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    _scrollable?.position.removeListener(_check);
    _scrollable = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_near) return widget.builder(context);
    _scheduleCheck();
    return widget.placeholder;
  }

  // Layout and viewport-size changes rebuild this widget without scrolling,
  // so every placeholder frame re-measures once after layout.
  void _scheduleCheck() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
  }

  void _check() {
    final scrollable = _scrollable;
    if (!mounted || _near || scrollable == null) return;
    final box = context.findRenderObject();
    final viewport = scrollable.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox) return;
    if (!box.hasSize || !viewport.hasSize || !box.attached) return;
    if (!_isNear(box, viewport, scrollable.axisDirection)) return;
    _detach();
    setState(() => _near = true);
  }

  bool _isNear(RenderBox box, RenderBox viewport, AxisDirection direction) {
    final origin = box.localToGlobal(Offset.zero, ancestor: viewport);
    final vertical = axisDirectionToAxis(direction) == Axis.vertical;
    final start = vertical ? origin.dy : origin.dx;
    final length = vertical ? box.size.height : box.size.width;
    final extent = vertical ? viewport.size.height : viewport.size.width;
    final lead = extent * widget.lead;
    return start < extent + lead && start + length > -lead;
  }
}
