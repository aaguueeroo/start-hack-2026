import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/constants/store_item_image_assets.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/store_item_art.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

String _formatLearningItemDisplayName(String baseName, int level) {
  final String roman = switch (level) {
    1 => 'I',
    2 => 'II',
    3 => 'III',
    _ => level.toString(),
  };
  return '$baseName $roman';
}

/// Layer above scroll content (same bounds as the store body stack): flies a
/// thumbnail from [fromRect] to [toRect] in **stack-local** coordinates, with a
/// quick minimize-style squeeze (genie-like asymmetric scale + perspective).
class StorePurchaseFlyOverlay extends StatefulWidget {
  const StorePurchaseFlyOverlay({
    super.key,
    required this.fromRect,
    required this.toRect,
    required this.item,
    required this.onFinished,
  });

  final Rect fromRect;
  final Rect toRect;
  final StoreItem item;
  final VoidCallback onFinished;

  @override
  State<StorePurchaseFlyOverlay> createState() =>
      _StorePurchaseFlyOverlayState();
}

class _StorePurchaseFlyOverlayState extends State<StorePurchaseFlyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: GameThemeConstants.storePurchaseFlyDuration,
      vsync: this,
    );
    _t = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward().then((_) {
      if (!mounted) return;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _t,
          builder: (BuildContext context, Widget? child) {
            final double t = _t.value;
            final Rect r = Rect.lerp(widget.fromRect, widget.toRect, t)!;
            final double squeeze = Curves.easeIn.transform(t);
            final double scaleX = lerpDouble(1.0, 0.42, squeeze)!;
            final double scaleY = lerpDouble(1.0, 0.58, squeeze)!;
            final Matrix4 perspectiveRot = Matrix4.identity()
              ..setEntry(3, 2, 0.0011)
              ..rotateX((1 - t) * 0.22)
              ..rotateY((1 - t) * 0.1);
            final Matrix4 squeezeM =
                Matrix4.diagonal3Values(scaleX, scaleY, 1.0);
            final Matrix4 m = perspectiveRot * squeezeM;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: r.left,
                  top: r.top,
                  width: r.width,
                  height: r.height,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: m,
                    child: Opacity(
                      opacity: 1.0 - 0.18 * t,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: widget.fromRect.width,
                          height: widget.fromRect.height,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: _StorePurchaseFlyThumbnail(item: widget.item),
        ),
      ),
    );
  }
}

class _StorePurchaseFlyThumbnail extends StatelessWidget {
  const _StorePurchaseFlyThumbnail({required this.item});

  final StoreItem item;

  Color _backgroundColor() {
    if (item is StoreItemAsset) {
      return GameThemeConstants.creamSurface;
    }
    return GameThemeConstants.getItemLevelColor((item as StoreItemItem).level);
  }

  String _title() {
    return switch (item) {
      StoreItemItem(:final name, :final level) =>
        _formatLearningItemDisplayName(name, level),
      _ => item.name,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GameCard(
      backgroundColor: _backgroundColor(),
      padding: const EdgeInsets.all(SpacingConstants.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          StoreItemArt(
            icon: item.icon,
            imagePath: switch (item) {
              StoreItemItem() =>
                StoreItemImageAssets.imagePathForKnowledgeItem(item.id),
              StoreItemAsset() =>
                StoreItemImageAssets.imagePathForStoreAsset(item.id),
            },
            size: 28,
          ),
          const SizedBox(height: SpacingConstants.xs),
          Text(
            _title(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Rect storePurchaseCenteredTargetRect(Rect bounds, {double size = 52}) {
  return Rect.fromCenter(center: bounds.center, width: size, height: size);
}
