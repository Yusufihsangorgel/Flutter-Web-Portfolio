import 'package:flutter/foundation.dart';

@immutable
final class SoundState {
  const SoundState({
    required this.isEnabled,
    required this.masterVolume,
    required this.isAmbientPlaying,
  });

  const SoundState.initial({required this.masterVolume})
    : isEnabled = false,
      isAmbientPlaying = false;

  final bool isEnabled;
  final double masterVolume;
  final bool isAmbientPlaying;

  SoundState copyWith({
    bool? isEnabled,
    double? masterVolume,
    bool? isAmbientPlaying,
  }) => SoundState(
    isEnabled: isEnabled ?? this.isEnabled,
    masterVolume: masterVolume ?? this.masterVolume,
    isAmbientPlaying: isAmbientPlaying ?? this.isAmbientPlaying,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundState &&
          isEnabled == other.isEnabled &&
          masterVolume == other.masterVolume &&
          isAmbientPlaying == other.isAmbientPlaying;

  @override
  int get hashCode => Object.hash(isEnabled, masterVolume, isAmbientPlaying);
}
