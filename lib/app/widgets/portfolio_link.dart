import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_portfolio/app/controllers/scroll_controller.dart';
import 'package:flutter_web_portfolio/app/utils/web_url_strategy.dart'
    as url_strategy;
import 'package:flutter_web_portfolio/app/widgets/accessible_action.dart';
import 'package:url_launcher/link.dart';

/// Exposes browser links with keyboard and pointer activation.
class PortfolioLink extends StatefulWidget {
  const PortfolioLink({
    super.key,
    required this.uri,
    required this.child,
    this.semanticLabel,
    this.onActivate,
    this.onHoverChanged,
    this.onFocusChanged,
    this.focusNode,
    this.focusColor,
    this.showFocusRing = true,
    this.borderRadius = BorderRadius.zero,
    this.selected,
  });

  final Uri uri;
  final Widget child;
  final String? semanticLabel;
  final VoidCallback? onActivate;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onFocusChanged;
  final FocusNode? focusNode;
  final Color? focusColor;
  final bool showFocusRing;
  final BorderRadius borderRadius;
  final bool? selected;

  @override
  State<PortfolioLink> createState() => _PortfolioLinkState();
}

class _PortfolioLinkState extends State<PortfolioLink> {
  @override
  void initState() {
    super.initState();
    url_strategy.interceptInPageLinkClicks();
  }

  String? get _chapter {
    final uri = widget.uri;
    if (uri.hasScheme || uri.hasAuthority || uri.path.isNotEmpty) return null;
    final fragment = uri.fragment;
    if (!fragment.startsWith('/')) return null;
    final chapter = fragment.substring(1);
    return chapter.isEmpty ? 'home' : chapter;
  }

  void _scrollToChapter() {
    final onActivate = widget.onActivate;
    if (onActivate != null) return onActivate();
    context.read<AppScrollController>().scrollToSection(_chapter!);
  }

  LinkTarget get _target {
    final scheme = widget.uri.scheme;
    return scheme == 'http' || scheme == 'https'
        ? LinkTarget.blank
        : LinkTarget.self;
  }

  Widget _action(VoidCallback onTap) => AccessibleAction(
    onTap: onTap,
    onHoverChanged: widget.onHoverChanged,
    onFocusChanged: widget.onFocusChanged,
    focusNode: widget.focusNode,
    focusColor: widget.focusColor,
    showFocusRing: widget.showFocusRing,
    excludeFromSemantics: true,
    semanticLabel: widget.semanticLabel,
    semanticRole: ActionSemanticRole.link,
    linkUrl: widget.uri,
    selected: widget.selected,
    borderRadius: widget.borderRadius,
    child: widget.child,
  );

  @override
  Widget build(BuildContext context) {
    if (_chapter != null) return _action(_scrollToChapter);
    return Link(
      uri: widget.uri,
      target: _target,
      builder: (context, followLink) =>
          _action(widget.onActivate ?? followLink!),
    );
  }
}
