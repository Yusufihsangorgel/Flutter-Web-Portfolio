import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@immutable
final class CursorUiState {
  const CursorUiState({this.isHovering = false, this.hoverAccent});

  final bool isHovering;
  final Color? hoverAccent;

  CursorUiState copyWith({
    bool? isHovering,
    Color? hoverAccent,
    bool clearHoverAccent = false,
  }) => CursorUiState(
    isHovering: isHovering ?? this.isHovering,
    hoverAccent: clearHoverAccent ? null : hoverAccent ?? this.hoverAccent,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursorUiState &&
          isHovering == other.isHovering &&
          hoverAccent == other.hoverAccent;

  @override
  int get hashCode => Object.hash(isHovering, hoverAccent);
}

/// Owns the low-frequency semantic state of the desktop cursor.
///
/// Pointer coordinates and spring physics deliberately remain widget-local;
/// publishing those 60/120 Hz values through application state would create
/// needless stream traffic and broad rebuilds.
final class CursorController extends Cubit<CursorUiState> {
  CursorController() : super(const CursorUiState());

  void setHovering(bool value) {
    if (state.isHovering == value) return;
    emit(state.copyWith(isHovering: value));
  }

  void setHoverAccent(Color? value) {
    if (state.hoverAccent == value) return;
    emit(
      value == null
          ? state.copyWith(clearHoverAccent: true)
          : state.copyWith(hoverAccent: value),
    );
  }
}
