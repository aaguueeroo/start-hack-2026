import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/comic_tooltip_arrow_painter.dart';
import 'package:start_hack_2026/core/widgets/popup_enter_exit_transition.dart';

/// Positions a comic-style tooltip above or below [cardPosition] / [cardSize].
class ComicTooltipAnchoredPopup extends StatelessWidget {
  const ComicTooltipAnchoredPopup({
    super.key,
    required this.cardPosition,
    required this.cardSize,
    required this.tooltipWidth,
    required this.content,
    this.arrowHeight = 12,
    this.transitionKey,
    this.onDismissComplete,
  });

  final Offset cardPosition;
  final Size cardSize;
  final double tooltipWidth;
  final Widget content;
  final double arrowHeight;
  final GlobalKey<PopupEnterExitTransitionState>? transitionKey;
  final VoidCallback? onDismissComplete;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const spacing = SpacingConstants.sm;
    final cardCenterX = cardPosition.dx + cardSize.width / 2;
    var tooltipLeft = cardCenterX - tooltipWidth / 2;
    tooltipLeft = tooltipLeft.clamp(
      SpacingConstants.md,
      screenWidth - tooltipWidth - SpacingConstants.md,
    );
    final arrowCenterX = cardCenterX - tooltipLeft;
    final showAbove = cardPosition.dy > screenHeight / 2;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAbove) ...[
          content,
          CustomPaint(
            size: Size(tooltipWidth, arrowHeight),
            painter: ComicTooltipArrowPainter(
              color: GameThemeConstants.creamSurface,
              borderColor: GameThemeConstants.outlineColor,
              arrowCenterX: arrowCenterX,
              pointingDown: true,
            ),
          ),
        ] else ...[
          CustomPaint(
            size: Size(tooltipWidth, arrowHeight),
            painter: ComicTooltipArrowPainter(
              color: GameThemeConstants.creamSurface,
              borderColor: GameThemeConstants.outlineColor,
              arrowCenterX: arrowCenterX,
              pointingDown: false,
            ),
          ),
          content,
        ],
      ],
    );

    final materialChild = Material(
      color: Colors.transparent,
      child: column,
    );

    final positionedChild = transitionKey != null && onDismissComplete != null
        ? AnchoredTooltipPopupTransition(
            showAbove: showAbove,
            transitionKey: transitionKey,
            onComplete: onDismissComplete,
            child: materialChild,
          )
        : materialChild;

    return Positioned(
      left: tooltipLeft,
      top: showAbove ? null : cardPosition.dy + cardSize.height + spacing,
      bottom: showAbove ? screenHeight - cardPosition.dy + spacing : null,
      width: tooltipWidth,
      child: positionedChild,
    );
  }
}

/// Vertical placement of a [ComicTooltipFollowerAnchored] relative to the leader.
enum ComicTooltipFollowerPlacement {
  /// Tooltip sits above the leader; arrow points down toward the anchor.
  above,

  /// Tooltip sits below the leader; arrow points up toward the anchor.
  below,
}

/// Tooltip anchored to a [CompositedTransformTarget] — follows scroll/transforms.
///
/// Horizontally shifts the tooltip and arrow so the panel stays within the
/// screen (padding [SpacingConstants.md]) while the arrow tip stays aligned
/// with the leader anchor on the X axis.
class ComicTooltipFollowerAnchored extends StatefulWidget {
  const ComicTooltipFollowerAnchored({
    super.key,
    required this.layerLink,
    required this.placement,
    required this.tooltipWidth,
    required this.content,
    this.leaderTargetKey,
    this.gap = 6,
    this.arrowHeight = 12,
  });

  final LayerLink layerLink;
  final ComicTooltipFollowerPlacement placement;
  final double tooltipWidth;
  final Widget content;

  /// When set, used to read the leader [RenderBox] for viewport clamping and
  /// for converting [CompositedTransformFollower.offset] into the leader's
  /// coordinate space.
  final GlobalKey? leaderTargetKey;
  final double gap;
  final double arrowHeight;

  @override
  State<ComicTooltipFollowerAnchored> createState() =>
      _ComicTooltipFollowerAnchoredState();
}

class _ComicTooltipFollowerAnchoredState
    extends State<ComicTooltipFollowerAnchored> {
  double _horizontalOffset = 0;
  double _arrowCenterX = 0;
  bool _clampReady = false;
  bool _stopClampUpdates = false;

  @override
  void initState() {
    super.initState();
    if (widget.leaderTargetKey != null) {
      _scheduleClampUpdate();
    }
  }

  void _scheduleClampUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || _stopClampUpdates || widget.leaderTargetKey == null) {
        return;
      }
      _updateViewportClamp();
      _scheduleClampUpdate();
    });
  }

  CrossAxisAlignment _columnCrossAxis() {
    switch (widget.placement) {
      case ComicTooltipFollowerPlacement.above:
        return CrossAxisAlignment.stretch;
      case ComicTooltipFollowerPlacement.below:
        return CrossAxisAlignment.center;
    }
  }

  @override
  void dispose() {
    _stopClampUpdates = true;
    super.dispose();
  }

  void _updateViewportClamp() {
    final GlobalKey? targetKey = widget.leaderTargetKey;
    if (targetKey == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final BuildContext? leaderCtx = targetKey.currentContext;
    if (leaderCtx == null || !leaderCtx.mounted) {
      return;
    }
    final RenderBox? leaderBox = leaderCtx.findRenderObject() as RenderBox?;
    if (leaderBox == null || !leaderBox.hasSize || !leaderBox.attached) {
      return;
    }
    final BuildContext overlayCtx = context;
    final double screenW = MediaQuery.sizeOf(overlayCtx).width;
    final EdgeInsets viewPadding = MediaQuery.paddingOf(overlayCtx);
    final double maxW =
        screenW - SpacingConstants.md * 2 - viewPadding.left - viewPadding.right;
    final double w =
        math.max(120.0, math.min(widget.tooltipWidth, maxW)).toDouble();
    final Offset anchorLocal =
        widget.placement == ComicTooltipFollowerPlacement.above
        ? Offset(leaderBox.size.width / 2, 0)
        : Offset(leaderBox.size.width / 2, leaderBox.size.height);
    final Offset anchorGlobal = leaderBox.localToGlobal(anchorLocal);
    final double padL = SpacingConstants.md + viewPadding.left;
    final double padR = SpacingConstants.md + viewPadding.right;
    final double idealLeft = anchorGlobal.dx - w / 2;
    final double clampedLeft = idealLeft.clamp(
      padL,
      math.max(padL, screenW - padR - w),
    );
    final Offset shiftedAnchorGlobal = Offset(
      clampedLeft + w / 2,
      anchorGlobal.dy,
    );
    final Offset offsetInLeader =
        leaderBox.globalToLocal(shiftedAnchorGlobal) - anchorLocal;
    final double newHorizontalOffset = offsetInLeader.dx;
    final double newArrowCenterX = anchorGlobal.dx - clampedLeft;
    if (!_clampReady ||
        (newHorizontalOffset - _horizontalOffset).abs() > 0.25 ||
        (newArrowCenterX - _arrowCenterX).abs() > 0.25) {
      setState(() {
        _horizontalOffset = newHorizontalOffset;
        _arrowCenterX = newArrowCenterX;
        _clampReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.sizeOf(context).width;
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final double maxW =
        screenW - SpacingConstants.md * 2 - viewPadding.left - viewPadding.right;
    final double w =
        math.max(120.0, math.min(widget.tooltipWidth, maxW)).toDouble();
    final bool isAbove =
        widget.placement == ComicTooltipFollowerPlacement.above;
    final double verticalOffset = isAbove ? -widget.gap : widget.gap;
    final Alignment targetAnchor =
        isAbove ? Alignment.topCenter : Alignment.bottomCenter;
    final Alignment followerAnchor =
        isAbove ? Alignment.bottomCenter : Alignment.topCenter;
    final bool hasLeaderKey = widget.leaderTargetKey != null;
    final double horizontal =
        hasLeaderKey && _clampReady ? _horizontalOffset : 0;
    final double arrowX =
        hasLeaderKey && _clampReady ? _arrowCenterX : w / 2;

    return CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: Offset(horizontal, verticalOffset),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _columnCrossAxis(),
          children: [
            if (isAbove) ...[
              SizedBox(width: w, child: widget.content),
              CustomPaint(
                size: Size(w, widget.arrowHeight),
                painter: ComicTooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowX,
                  pointingDown: true,
                ),
              ),
            ] else ...[
              CustomPaint(
                size: Size(w, widget.arrowHeight),
                painter: ComicTooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowX,
                  pointingDown: false,
                ),
              ),
              SizedBox(width: w, child: widget.content),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tooltip anchored under a [CompositedTransformTarget] — follows scroll/transforms.
class ComicTooltipFollowerBelow extends StatelessWidget {
  const ComicTooltipFollowerBelow({
    super.key,
    required this.layerLink,
    required this.tooltipWidth,
    required this.content,
    this.leaderTargetKey,
    this.gap = 6,
    this.arrowHeight = 12,
  });

  final LayerLink layerLink;
  final double tooltipWidth;
  final Widget content;
  final GlobalKey? leaderTargetKey;
  final double gap;
  final double arrowHeight;

  @override
  Widget build(BuildContext context) {
    return ComicTooltipFollowerAnchored(
      layerLink: layerLink,
      placement: ComicTooltipFollowerPlacement.below,
      tooltipWidth: tooltipWidth,
      content: content,
      leaderTargetKey: leaderTargetKey,
      gap: gap,
      arrowHeight: arrowHeight,
    );
  }
}
