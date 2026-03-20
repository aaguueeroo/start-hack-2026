import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';

/// Curves used for popup enter (easeOutCubic) and exit (easeInCubic).
const Curve _popupEnterCurve = Curves.easeOutCubic;
const Curve _popupExitCurve = Curves.easeInCubic;

/// Combines fade, scale (toward anchor), and slide for popup enter/exit.
/// Forward on mount; call [animateOut] for exit, then [onComplete] when done.
class PopupEnterExitTransition extends StatefulWidget {
  const PopupEnterExitTransition({
    super.key,
    required this.child,
    required this.scaleAlignment,
    required this.slideBegin,
    this.enterDuration,
    this.exitDuration,
    this.onComplete,
  });

  final Widget child;
  final Alignment scaleAlignment;
  final Offset slideBegin;
  final Duration? enterDuration;
  final Duration? exitDuration;
  final VoidCallback? onComplete;

  @override
  PopupEnterExitTransitionState createState() =>
      PopupEnterExitTransitionState();
}

/// State for [PopupEnterExitTransition]; exposes [animateOut] for programmatic dismiss.
class PopupEnterExitTransitionState extends State<PopupEnterExitTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final enterDuration =
        widget.enterDuration ?? GameThemeConstants.anchoredPopupEnterDuration;
    final exitDuration =
        widget.exitDuration ?? GameThemeConstants.anchoredPopupExitDuration;
    _controller = AnimationController(
      vsync: this,
      duration: enterDuration,
      reverseDuration: exitDuration,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: _popupEnterCurve,
      reverseCurve: _popupExitCurve,
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _popupEnterCurve,
        reverseCurve: _popupExitCurve,
      ),
    );
    _slide = Tween<Offset>(
      begin: widget.slideBegin,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: _popupEnterCurve,
        reverseCurve: _popupExitCurve,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> animateOut() async {
    await _controller.reverse();
    if (mounted) widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: widget.scaleAlignment,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wrapper that computes [scaleAlignment] and [slideBegin] from [showAbove].
/// Tooltip above anchor: scale/slide from bottom-center; below: top-center.
class AnchoredTooltipPopupTransition extends StatelessWidget {
  const AnchoredTooltipPopupTransition({
    super.key,
    required this.showAbove,
    required this.child,
    this.transitionKey,
    this.enterDuration,
    this.exitDuration,
    this.onComplete,
  });

  final bool showAbove;
  final Widget child;
  final Key? transitionKey;
  final Duration? enterDuration;
  final Duration? exitDuration;
  final VoidCallback? onComplete;

  static const Offset _slideOffsetAbove = Offset(0, 0.03);
  static const Offset _slideOffsetBelow = Offset(0, -0.03);

  @override
  Widget build(BuildContext context) {
    final scaleAlignment =
        showAbove ? Alignment.bottomCenter : Alignment.topCenter;
    final slideBegin = showAbove ? _slideOffsetAbove : _slideOffsetBelow;
    return PopupEnterExitTransition(
      key: transitionKey,
      scaleAlignment: scaleAlignment,
      slideBegin: slideBegin,
      enterDuration: enterDuration,
      exitDuration: exitDuration,
      onComplete: onComplete,
      child: child,
    );
  }
}
