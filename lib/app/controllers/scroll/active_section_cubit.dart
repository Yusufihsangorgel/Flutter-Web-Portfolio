import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_web_portfolio/app/controllers/scroll/browser_history.dart';

/// The chapter shown as active in navigation.
@immutable
final class AppScrollState {
  const AppScrollState({this.activeSection = 'home'});

  final String activeSection;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppScrollState && activeSection == other.activeSection;

  @override
  int get hashCode => activeSection.hashCode;
}

/// How a chapter change is written to browser history.
enum HistoryWrite { none, push, replace }

/// Holds the active chapter and mirrors changes into browser history.
class ActiveSectionCubit extends Cubit<AppScrollState> {
  ActiveSectionCubit(this.history) : super(const AppScrollState());

  final BrowserHistory history;

  String get activeSection => state.activeSection;

  void setActiveSection(
    String section, {
    HistoryWrite write = HistoryWrite.none,
  }) {
    if (isClosed) return;
    if (state.activeSection == section) return;
    emit(AppScrollState(activeSection: section));
    switch (write) {
      case HistoryWrite.none:
        break;
      case HistoryWrite.push:
        history.pushHash(section);
      case HistoryWrite.replace:
        history.replaceHash(section);
    }
  }
}
