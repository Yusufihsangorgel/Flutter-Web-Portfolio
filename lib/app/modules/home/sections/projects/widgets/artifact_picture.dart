import 'package:flutter/material.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/artifact_view.dart';
import 'package:flutter_web_portfolio/app/modules/home/sections/projects/widgets/viewport_proximity_gate.dart';
import 'package:flutter_web_portfolio/app/utils/work_artifact_marks.dart';

/// A lazily loaded artifact image announced as one image to assistive tech.
///
/// Its semantics identifier names the asset, and [onPainted] reports the asset
/// once the decoded image has been painted. Browser tests pair the two to wait
/// for every visible artifact before capturing.
final class ArtifactPicture extends StatefulWidget {
  const ArtifactPicture({
    super.key,
    required this.view,
    required this.image,
    this.onPainted = markWorkArtifactPainted,
  });

  static const identifierPrefix = 'work-artifact:';

  final ArtifactView view;
  final ImageProvider image;
  final ValueChanged<String> onPainted;

  @override
  State<ArtifactPicture> createState() => _ArtifactPictureState();
}

final class _ArtifactPictureState extends State<ArtifactPicture> {
  bool _reported = false;

  @override
  void didUpdateWidget(covariant ArtifactPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _reported = false;
  }

  // The first non-null frame is painted in the frame that delivers it.
  void _onFrame(int? frame) {
    if (frame == null || _reported) return;
    _reported = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPainted(widget.view.asset);
    });
  }

  // Flutter does not resend a node whose only change is its identifier, so
  // the identifier stays constant and readiness travels through [onPainted].
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.view.alt,
    identifier: '${ArtifactPicture.identifierPrefix}${widget.view.asset}',
    excludeSemantics: true,
    child: ViewportProximityGate(
      builder: (context) => Image(
        image: widget.image,
        fit: widget.view.fit,
        alignment: widget.view.alignment,
        filterQuality: FilterQuality.high,
        frameBuilder: (context, child, frame, _) {
          _onFrame(frame);
          return child;
        },
      ),
    ),
  );
}
