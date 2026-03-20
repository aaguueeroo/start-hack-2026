import 'package:flutter/material.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/constants/store_asset_education.dart';
import 'package:start_hack_2026/core/widgets/comic_tooltip_anchored_popup.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';

/// Width for store asset education (wider than held-asset stats tooltip).
const double kStoreAssetEducationTooltipWidth = 276;

/// Anchored to [layerLink] via [CompositedTransformTarget] on the store card —
/// follows the card while the store scrolls.
class StoreAssetEducationPanel extends StatelessWidget {
  const StoreAssetEducationPanel({
    super.key,
    required this.layerLink,
    required this.asset,
    required this.onDismiss,
  });

  final LayerLink layerLink;
  final StoreItemAsset asset;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: const SizedBox.expand(),
          ),
        ),
        ComicTooltipFollowerBelow(
          layerLink: layerLink,
          tooltipWidth: kStoreAssetEducationTooltipWidth,
          content: _StoreAssetEducationCard(
            asset: asset,
            onDismiss: onDismiss,
          ),
        ),
      ],
    );
  }
}

class _StoreAssetEducationCard extends StatelessWidget {
  const _StoreAssetEducationCard({
    required this.asset,
    required this.onDismiss,
  });

  final StoreItemAsset asset;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final edu = StoreAssetEducation.forAsset(asset);
    final maxBodyHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Container(
      padding: const EdgeInsets.all(SpacingConstants.sm),
      decoration: BoxDecoration(
        color: GameThemeConstants.creamSurface,
        borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThickness,
        ),
        boxShadow: [
          BoxShadow(
            color: GameThemeConstants.outlineColor.withValues(alpha: 0.15),
            offset: const Offset(0, GameThemeConstants.bevelOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      asset.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: GameThemeConstants.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    tooltip: 'Close',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: GameThemeConstants.outlineColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: SpacingConstants.xs),
              Text(
                'Expected ${asset.expectedReturn >= 0 ? '+' : ''}'
                '${asset.expectedReturn.toStringAsFixed(1)}% · '
                'Volatility ${asset.volatility.toStringAsFixed(1)}% · '
                'Liquidity ${asset.liquidity.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: GameThemeConstants.outlineColorLight,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: SpacingConstants.sm),
              _SectionTitle(label: 'What it is'),
              const SizedBox(height: SpacingConstants.xs),
              Text(
                edu.kind,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GameThemeConstants.outlineColor,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: SpacingConstants.sm),
              _SectionTitle(label: 'How it works'),
              const SizedBox(height: SpacingConstants.xs),
              Text(
                edu.howItWorks,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GameThemeConstants.outlineColor,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: SpacingConstants.sm),
              _SectionTitle(label: 'Risks'),
              const SizedBox(height: SpacingConstants.xs),
              Text(
                edu.risks,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GameThemeConstants.statNegative,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (asset.flavourText != null &&
                  asset.flavourText!.trim().isNotEmpty) ...[
                const SizedBox(height: SpacingConstants.sm),
                Text(
                  '“${asset.flavourText}”',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GameThemeConstants.outlineColorLight,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
        color: GameThemeConstants.primaryDark,
        fontSize: 10,
      ),
    );
  }
}
