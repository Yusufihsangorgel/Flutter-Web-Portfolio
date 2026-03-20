import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reactive hover state for the custom cursor overlay.
class CursorController extends GetxController {
  final isHovering = false.obs;
  final hoverAccent = Rxn<Color>();
}
