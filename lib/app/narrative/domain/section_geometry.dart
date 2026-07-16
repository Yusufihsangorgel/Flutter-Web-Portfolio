import 'package:flutter/foundation.dart';

/// Measured document geometry for one portfolio chapter.
///
/// Navigation, URL state, boundary transitions, and the scene engine share
/// this coordinate system so every consumer describes the same reading point.
@immutable
final class SectionGeometry {
  const SectionGeometry({
    required this.id,
    required this.top,
    required this.height,
  });

  final String id;
  final double top;
  final double height;

  double get center => top + height / 2;
  double get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionGeometry &&
          id == other.id &&
          top == other.top &&
          height == other.height;

  @override
  int get hashCode => Object.hash(id, top, height);
}
