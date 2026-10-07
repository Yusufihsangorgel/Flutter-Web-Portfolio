import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
      _scrollable = scrollable..position.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    _scrollable?.position.removeListener(_onScroll);
    _scrollable = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_near) return widget.builder(context);
    _scheduleCheck();
    return widget.placeholder;
  }

  // Every offset change (wheel, animation, jump, restore) is measured at once,
  // except during layout, and again after the next layout.
  void _onScroll() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase != SchedulerPhase.persistentCallbacks) _check();
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_near || _checkScheduled) return;
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
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    if (!_isNear(box, scrollable.position)) return;
    _detach();
    setState(() => _near = true);
  }

  // Document-space bounds against the current offset: a jump updates the
  // offset before the viewport lays out, so painted positions may be stale.
  bool _isNear(RenderBox box, ScrollPosition position) {
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return true;
    if (!position.hasPixels || !position.hasViewportDimension) return false;
    final reveal = viewport.getOffsetToReveal(box, 0).offset;
    final leading = reveal - position.pixels;
    final vertical = position.axis == Axis.vertical;
    final length = vertical ? box.size.height : box.size.width;
    final extent = position.viewportDimension;
    final lead = extent * widget.lead;
    return leading < extent + lead && leading + length > -lead;
  }
}
