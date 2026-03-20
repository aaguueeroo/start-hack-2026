import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/comic_tooltip_arrow_painter.dart';

/// Positions a comic-style tooltip above or below [cardPosition] / [cardSize].
class ComicTooltipAnchoredPopup extends StatelessWidget {
  const ComicTooltipAnchoredPopup({
    super.key,
    required this.cardPosition,
    required this.cardSize,
    required this.tooltipWidth,
    required this.content,
    this.arrowHeight = 12,
  });

  final Offset cardPosition;
  final Size cardSize;
  final double tooltipWidth;
  final Widget content;
  final double arrowHeight;

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

    return Positioned(
      left: tooltipLeft,
      top: showAbove ? null : cardPosition.dy + cardSize.height + spacing,
      bottom: showAbove ? screenHeight - cardPosition.dy + spacing : null,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Column(
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
    this.gap = 6,
    this.arrowHeight = 12,
  });

  final LayerLink layerLink;
  final double tooltipWidth;
  final Widget content;
  final double gap;
  final double arrowHeight;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final maxW = screenW - SpacingConstants.md * 2;
    final w = math.max(120.0, math.min(tooltipWidth, maxW)).toDouble();

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      offset: Offset(0, gap),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomPaint(
              size: Size(w, arrowHeight),
              painter: ComicTooltipArrowPainter(
                color: GameThemeConstants.creamSurface,
                borderColor: GameThemeConstants.outlineColor,
                arrowCenterX: w / 2,
                pointingDown: false,
              ),
            ),
            SizedBox(width: w, child: content),
          ],
        ),
      ),
    );
  }
}
