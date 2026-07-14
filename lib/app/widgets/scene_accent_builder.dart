import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scene_director.dart';

/// Rebuilds only when the scene's effective accent changes.
///
/// This keeps scroll-driven scene state granular: content cards do not rebuild
/// for progress updates that leave their color unchanged.
final class SceneAccentBuilder extends StatelessWidget {
  const SceneAccentBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Color accent) builder;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SceneDirector, SceneState, Color>(
        selector: (state) => state.currentAccent,
        builder: builder,
      );
}
