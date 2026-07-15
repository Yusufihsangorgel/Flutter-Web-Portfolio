import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

bool prefersReducedMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
