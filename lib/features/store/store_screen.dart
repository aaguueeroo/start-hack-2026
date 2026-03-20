import 'dart:async' show Completer, unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/character_image_constants.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';
import 'package:start_hack_2026/core/widgets/character_preview_stat_bars.dart';
import 'package:start_hack_2026/core/widgets/cartoon_play_icon.dart';
import 'package:start_hack_2026/core/widgets/comic_tooltip_anchored_popup.dart';
import 'package:start_hack_2026/core/widgets/comic_tooltip_arrow_painter.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/portfolio_evolution_chart.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/features/store/store_asset_education_overlay.dart';
import 'package:start_hack_2026/features/store/store_purchase_fly_overlay.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

const String _coinAssetPath = 'assets/images/coin.png';
const String _allocationChartAssetPath = 'assets/images/chart.png';

enum _StoreHudPanel { character }

double? _getBaselineValueForComparison(StoreController controller) {
  final currentYear = controller.currentYear;
  if (currentYear > 1) {
    final lastYearPoint = controller.portfolioHistory
        .where((p) => p.year == currentYear - 1)
        .firstOrNull;
    return lastYearPoint?.value;
  }
  final year1Point = controller.portfolioHistory
      .where((p) => p.year == 1)
      .firstOrNull;
  return year1Point?.value;
}

String _formatLearningItemDisplayName(String baseName, int level) {
  final String roman = switch (level) {
    1 => 'I',
    2 => 'II',
    3 => 'III',
    _ => level.toString(),
  };
  return '$baseName $roman';
}

class _PurchaseFlyInProgress {
  const _PurchaseFlyInProgress({
    required this.item,
    required this.fromRect,
    required this.toRect,
    required this.onFinished,
  });

  final StoreItem item;
  final Rect fromRect;
  final Rect toRect;
  final VoidCallback onFinished;
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final GlobalKey _portfolioButtonKey = GlobalKey();
  final GlobalKey _purchaseFlyStackKey = GlobalKey();
  OverlayEntry? _portfolioOverlayEntry;
  OverlayEntry? _storeAssetEducationOverlayEntry;
  _StoreHudPanel? _activeHudPanel;
  late final List<GlobalKey> _itemSlotKeys;
  final GlobalKey _assetSectionContentKey = GlobalKey();
  final Map<String, GlobalKey> _storeCardKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _assetCardKeys = <String, GlobalKey>{};
  final Map<String, LayerLink> _storeOfferLayerLinks = <String, LayerLink>{};
  _PurchaseFlyInProgress? _purchaseFly;

  @override
  void initState() {
    super.initState();
    _itemSlotKeys = List<GlobalKey>.generate(6, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().loadStoreData();
    });
  }

  String _storeItemStorageKey(StoreItem item) {
    switch (item) {
      case StoreItemItem(:final id, :final level):
        return 'store_item_${id}_$level';
      case StoreItemAsset(:final id):
        return 'store_asset_$id';
    }
  }

  GlobalKey _globalKeyForStoreCard(StoreItem item) {
    final String k = _storeItemStorageKey(item);
    return _storeCardKeys.putIfAbsent(k, GlobalKey.new);
  }

  GlobalKey _globalKeyForAssetCard(String assetId) {
    return _assetCardKeys.putIfAbsent(assetId, GlobalKey.new);
  }

  LayerLink _layerLinkForStoreOfferSlot(int index, StoreItem item) {
    final k = '$index-${_storeItemStorageKey(item)}';
    return _storeOfferLayerLinks.putIfAbsent(k, LayerLink.new);
  }

  Rect? _rectFromContext(BuildContext? ctx) {
    if (ctx == null) return null;
    final RenderObject? ro = ctx.findRenderObject();
    final RenderBox? box = ro is RenderBox ? ro : null;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _resolveDestinationRect(StoreController c, StoreItem item) {
    switch (item) {
      case StoreItemItem i:
        final int? slot = c.getKnowledgePurchaseTargetSlot(i);
        if (slot == null || slot < 0 || slot >= _itemSlotKeys.length) {
          return null;
        }
        return _rectFromContext(_itemSlotKeys[slot].currentContext);
      case StoreItemAsset a:
        if (c.hasExistingAssetHolding(a.id)) {
          final GlobalKey? key = _assetCardKeys[a.id];
          return _rectFromContext(key?.currentContext);
        }
        final Rect? section = _rectFromContext(
          _assetSectionContentKey.currentContext,
        );
        if (section == null) return null;
        return storePurchaseCenteredTargetRect(section);
    }
  }

  Future<void> _onStorePurchase(
    StoreItem item,
    GlobalKey sourceKey,
    int offerIndex,
  ) async {
    final StoreController controller = context.read<StoreController>();
    if (!controller.canBuy(item)) return;
    try {
      final Rect? dest = _resolveDestinationRect(controller, item);
      final BuildContext? sourceContext = sourceKey.currentContext;
      if (dest == null || sourceContext == null) {
        controller.purchase(item, offerIndex: offerIndex);
        return;
      }
      final RenderObject? ro = sourceContext.findRenderObject();
      final RenderBox? sourceBox = ro is RenderBox ? ro : null;
      if (sourceBox == null || !sourceBox.hasSize) {
        controller.purchase(item, offerIndex: offerIndex);
        return;
      }
      final Rect sourceRect =
          sourceBox.localToGlobal(Offset.zero) & sourceBox.size;
      if (!mounted) return;
      final BuildContext? stackCtx = _purchaseFlyStackKey.currentContext;
      final RenderObject? stackRo = stackCtx?.findRenderObject();
      final RenderBox? stackBox = stackRo is RenderBox ? stackRo : null;
      if (stackBox == null || !stackBox.hasSize) {
        controller.purchase(item, offerIndex: offerIndex);
        return;
      }
      final Offset stackOrigin = stackBox.localToGlobal(Offset.zero);
      final Rect localFrom = sourceRect.shift(-stackOrigin);
      final Rect localTo = dest.shift(-stackOrigin);
      final Completer<void> completer = Completer<void>();
      setState(() {
        _purchaseFly = _PurchaseFlyInProgress(
          item: item,
          fromRect: localFrom,
          toRect: localTo,
          onFinished: () {
            if (!mounted) return;
            setState(() {
              _purchaseFly = null;
            });
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
      });
      await completer.future;
      if (!mounted) return;
      controller.purchase(item, offerIndex: offerIndex);
    } catch (e, st) {
      if (kDebugMode) {
        print('Store purchase animation failed: $e\n$st');
      }
      if (mounted) {
        controller.purchase(item, offerIndex: offerIndex);
      }
    }
  }

  void _showPortfolioOverlay(BuildContext context, StoreController controller) {
    _hidePortfolioOverlay();
    _portfolioOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: _PortfolioOverlay(
          portfolioButtonKey: _portfolioButtonKey,
          portfolioHistory: controller.portfolioHistory,
          currentPortfolioValue: controller.currentPortfolioValue,
          currentYear: controller.currentYear,
          onDismiss: _hidePortfolioOverlay,
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_portfolioOverlayEntry!);
  }

  void _hidePortfolioOverlay() {
    _portfolioOverlayEntry?.remove();
    _portfolioOverlayEntry = null;
  }

  void _showStoreAssetEducation(
    BuildContext context,
    LayerLink layerLink,
    StoreItemAsset asset,
  ) {
    _hideStoreAssetEducation();
    _storeAssetEducationOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: StoreAssetEducationPanel(
          layerLink: layerLink,
          asset: asset,
          onDismiss: _hideStoreAssetEducation,
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(
      _storeAssetEducationOverlayEntry!,
    );
  }

  void _hideStoreAssetEducation() {
    _storeAssetEducationOverlayEntry?.remove();
    _storeAssetEducationOverlayEntry = null;
  }

  @override
  void dispose() {
    _hidePortfolioOverlay();
    _hideStoreAssetEducation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreController>(
      builder: (context, controller, _) {
        final double safeBottomInset = MediaQuery.paddingOf(context).bottom;
        const double storeBottomBarHeight =
            SpacingConstants.md * 2 +
            SpacingConstants.xl +
            GameThemeConstants.bevelOffset;
        final double storeScrollBottomPadding =
            safeBottomInset +
            SpacingConstants.md +
            storeBottomBarHeight +
            SpacingConstants.sm;
        return Scaffold(
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
              ),
            ),
            child: controller.isLoading
                ? const Center(child: GameProgressIndicator())
                : controller.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingConstants.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: SpacingConstants.md),
                          GameButton(
                            label: 'Retry',
                            onPressed: () => controller.loadStoreData(),
                            variant: GameButtonVariant.primary,
                          ),
                        ],
                      ),
                    ),
                  )
                : controller.character == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No character selected.'),
                        const SizedBox(height: SpacingConstants.md),
                        GameButton(
                          label: 'Choose Character',
                          onPressed: () => context.push('/character-selection'),
                          variant: GameButtonVariant.primary,
                        ),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned.fill(
                        child: Stack(
                          key: _purchaseFlyStackKey,
                          clipBehavior: Clip.none,
                          children: [
                            SingleChildScrollView(
                              padding: EdgeInsets.only(
                                left: SpacingConstants.md,
                                right: SpacingConstants.md,
                                top: SpacingConstants.md,
                                bottom: storeScrollBottomPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _TotalCapitalContainer(
                                    totalCapital:
                                        controller.currentPortfolioValue,
                                    baselineValue:
                                        _getBaselineValueForComparison(
                                          controller,
                                        ),
                                    showYearOverYearComparison:
                                        controller.currentYear > 1,
                                    comparisonYearLabel:
                                        controller.currentYear > 1
                                        ? (controller.currentYear - 1)
                                              .toString()
                                        : null,
                                  ),
                                  const SizedBox(height: SpacingConstants.lg),
                                  _BuySection(
                                    storeOffer: controller.storeOffer,
                                    canBuy: controller.canBuy,
                                    onPurchase: _onStorePurchase,
                                    keyForStoreCard: _globalKeyForStoreCard,
                                    onReshuffle: controller.reshuffleStoreOffer,
                                    reshuffleCost: controller.reshuffleCost,
                                    canReshuffle: controller.canReshuffle,
                                    statsSchema: controller.statsSchema,
                                    remainingAllocationPercent:
                                        controller.remainingAllocationPercent,
                                    cash: controller.cash,
                                    storeAssetAllocationPercentPerBuy:
                                        controller
                                            .storeAssetAllocationPercentPerBuy,
                                    getStoreAssetPurchaseCashCost: controller
                                        .getStoreAssetPurchaseCashCost,
                                    onShowStoreAssetEducation:
                                        _showStoreAssetEducation,
                                    layerLinkForStoreOfferSlot:
                                        _layerLinkForStoreOfferSlot,
                                  ),
                                  const SizedBox(height: SpacingConstants.lg),
                                  _ItemSlotsSection(
                                    itemSlotKeys: _itemSlotKeys,
                                    itemSlots: controller.itemSlots,
                                    statsSchema: controller.statsSchema,
                                    onCombine: controller.combineItems,
                                    canCombine: controller.canCombineItems,
                                  ),
                                  const SizedBox(height: SpacingConstants.sm),
                                  _StoreStatsPanel(
                                    stats: controller.stats,
                                    statSchemas: _filterStoreStatsByCategory(
                                      controller.statsSchema,
                                      controller.stats,
                                      'personal',
                                    ),
                                  ),
                                  const SizedBox(height: SpacingConstants.lg),
                                  _AssetSlotsSection(
                                    assetSectionContentKey:
                                        _assetSectionContentKey,
                                    getAssetCardKey: _globalKeyForAssetCard,
                                    holdings: controller.holdings,
                                    maxAssetSlots: controller.maxAssetSlots,
                                    totalAllocatedPercent:
                                        100 -
                                        controller.remainingAllocationPercent,
                                    getAssetAllocationPercent:
                                        controller.getAssetAllocationPercent,
                                    onSell: controller.sellAsset,
                                    statsSchema: controller.statsSchema,
                                    getAssetTotalReturnPercent:
                                        controller.getAssetTotalReturnPercent,
                                  ),
                                  const SizedBox(height: SpacingConstants.sm),
                                  _StoreStatsPanel(
                                    stats: controller.stats,
                                    statSchemas: _filterStoreStatsByCategory(
                                      controller.statsSchema,
                                      controller.stats,
                                      'portfolio',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_purchaseFly != null)
                              StorePurchaseFlyOverlay(
                                fromRect: _purchaseFly!.fromRect,
                                toRect: _purchaseFly!.toRect,
                                item: _purchaseFly!.item,
                                onFinished: _purchaseFly!.onFinished,
                              ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: SpacingConstants.md,
                        right: SpacingConstants.md,
                        bottom: safeBottomInset + SpacingConstants.md,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GameButton(
                                label: controller.shouldShowResults
                                    ? 'View Results'
                                    : 'Play',
                                icon: controller.shouldShowResults
                                    ? (controller.isBankrupt
                                        ? Icons.money_off
                                        : Icons.emoji_events)
                                    : null,
                                iconWidget: controller.shouldShowResults
                                    ? null
                                    : const CartoonPlayIcon(),
                                onPressed: () {
                                  if (controller.shouldShowResults) {
                                    context.pushReplacement('/game-won');
                                    return;
                                  }
                                  context.push('/simulation');
                                },
                                variant: GameButtonVariant.success,
                                isFullWidth: false,
                              ),
                            ),
                            const SizedBox(width: SpacingConstants.sm),
                            GestureDetector(
                              onLongPressDown: (_) =>
                                  _showPortfolioOverlay(context, controller),
                              onLongPressUp: _hidePortfolioOverlay,
                              onLongPressCancel: _hidePortfolioOverlay,
                              child: SizedBox(
                                key: _portfolioButtonKey,
                                width: 52,
                                height: 52,
                                child: const _CartoonCircleButton(
                                  icon: Icons.show_chart,
                                  onPressed: null,
                                ),
                              ),
                            ),
                            const SizedBox(width: SpacingConstants.sm),
                            _CartoonCircleButton(
                              icon: Icons.person,
                              onPressed: () {
                                setState(() {
                                  _activeHudPanel =
                                      _activeHudPanel == _StoreHudPanel.character
                                          ? null
                                          : _StoreHudPanel.character;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.bug_report),
                                onPressed: () =>
                                    context.push('/simulation-debug'),
                                tooltip: 'Debug',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_activeHudPanel != null)
                        _StoreHudOverlay(
                          controller: controller,
                          bottomBarHeight: storeBottomBarHeight,
                          safeBottomInset: safeBottomInset,
                          onDismiss: () =>
                              setState(() => _activeHudPanel = null),
                        ),
                    ],
                  ),
            ),
          ),
        );
      },
    );
  }
}

class _StoreHudOverlay extends StatelessWidget {
  const _StoreHudOverlay({
    required this.controller,
    required this.bottomBarHeight,
    required this.safeBottomInset,
    required this.onDismiss,
  });

  final StoreController controller;
  final double bottomBarHeight;
  final double safeBottomInset;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxPopupHeight = screenHeight * 0.6;
    final popupBottom = safeBottomInset + SpacingConstants.md + bottomBarHeight +
        SpacingConstants.sm;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerUp: (_) => onDismiss(),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: SpacingConstants.md,
            right: SpacingConstants.md,
            bottom: popupBottom,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPopupHeight),
              child: GameCard(
                child: SingleChildScrollView(
                  child: _StoreHudCharacterContent(
                    character: controller.character!,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreHudCharacterContent extends StatelessWidget {
  const _StoreHudCharacterContent({required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final imagePath =
        CharacterImageConstants.getImagePathForCharacter(character.id);
    return Padding(
      padding: const EdgeInsets.all(SpacingConstants.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            character.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: GameThemeConstants.primaryDark,
            ),
          ),
          const SizedBox(height: SpacingConstants.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        character.icon.toIconData(),
                        color: GameThemeConstants.primaryDark,
                        size: 48,
                      ),
              ),
              const SizedBox(width: SpacingConstants.md),
              Expanded(
                child: CharacterPreviewStatBars(stats: character.initialStats),
              ),
            ],
          ),
          const SizedBox(height: SpacingConstants.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConstants.sm,
              vertical: SpacingConstants.xs,
            ),
            decoration: BoxDecoration(
              color: GameThemeConstants.accentLight.withValues(alpha: 0.28),
              borderRadius:
                  BorderRadius.circular(SpacingConstants.gameRadiusSm),
              border: Border.all(
                color: GameThemeConstants.outlineColor,
                width: GameThemeConstants.outlineThicknessSmall,
              ),
            ),
            child: Text(
              character.uniqueSkill,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: GameThemeConstants.outlineColorLight,
                height: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartoonCircleButton extends StatelessWidget {
  const _CartoonCircleButton({
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameThemeConstants.primaryLight,
              GameThemeConstants.primaryDark,
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: GameThemeConstants.outlineColor,
            width: GameThemeConstants.outlineThickness,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D2E8C),
              offset: const Offset(0, GameThemeConstants.bevelOffset),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _TotalCapitalContainer extends StatelessWidget {
  const _TotalCapitalContainer({
    required this.totalCapital,
    required this.baselineValue,
    required this.showYearOverYearComparison,
    required this.comparisonYearLabel,
  });

  final double totalCapital;
  final double? baselineValue;
  final bool showYearOverYearComparison;
  final String? comparisonYearLabel;

  @override
  Widget build(BuildContext context) {
    final hasBaseline = baselineValue != null;
    final diff = hasBaseline ? totalCapital - baselineValue! : 0.0;
    final isGrowing = diff > 0;
    final isDecreasing = diff < 0;
    final valueColor = hasBaseline
        ? (isGrowing
              ? GameThemeConstants.statPositive
              : isDecreasing
              ? GameThemeConstants.statNegative
              : GameThemeConstants.primaryDark)
        : GameThemeConstants.primaryDark;

    final showYoYPanel = showYearOverYearComparison &&
        hasBaseline &&
        comparisonYearLabel != null;
    final baselineNonZero =
        hasBaseline && baselineValue!.abs() >= 1e-6;
    final pctChange = baselineNonZero ? (diff / baselineValue!) * 100.0 : null;

    final deltaColor = !hasBaseline
        ? GameThemeConstants.outlineColorLight
        : (isGrowing
            ? GameThemeConstants.statPositive
            : isDecreasing
            ? GameThemeConstants.statNegative
            : GameThemeConstants.outlineColorLight);

    final String absLine = !hasBaseline
        ? '—'
        : '${diff >= 0 ? '+' : '−'}${diff.abs().toStringAsFixed(0)}';
    final String pctLine = pctChange == null
        ? (baselineNonZero ? '0.0%' : '—')
        : '${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(1)}%';

    return SizedBox(
      width: double.infinity,
      child: GameCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Total Capital',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: GameThemeConstants.outlineColorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: SpacingConstants.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showYoYPanel) ...[
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'vs year $comparisonYearLabel',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                            color: GameThemeConstants.outlineColorLight,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          absLine + '\$',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                            color: deltaColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          pctLine,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                            color: deltaColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  flex: showYoYPanel ? 3 : 1,
                  child: Row(
                    mainAxisAlignment: showYoYPanel
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 48,
                        color: valueColor,
                      ),
                      const SizedBox(width: SpacingConstants.xs),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: showYoYPanel
                              ? Alignment.centerRight
                              : Alignment.center,
                          child: Text(
                            totalCapital.toStringAsFixed(0),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 48,
                              color: valueColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<StatSchema> _filterStoreStatsByCategory(
  List<StatSchema> schema,
  Map<String, num> stats,
  String category,
) {
  final filtered = schema
      .where(
        (StatSchema s) =>
            stats.containsKey(s.id) &&
            s.id != 'money' &&
            s.category == category,
      )
      .toList();

  if (category == 'personal') {
    const fallbackPersonalStats = <String, String>{
      'riskTolerance': 'Risk Tolerance',
      'financialKnowledge': 'Financial Knowledge',
      'monthlySavings': 'Monthly Savings',
    };
    final existingIds = filtered.map((s) => s.id).toSet();
    for (final entry in fallbackPersonalStats.entries) {
      if (!stats.containsKey(entry.key) || existingIds.contains(entry.key)) {
        continue;
      }
      filtered.add(
        StatSchema(
          id: entry.key,
          displayName: entry.value,
          description: '',
          category: 'personal',
        ),
      );
    }
  }

  return filtered;
}

const _statIcons = <String, IconData>{
  'money': Icons.attach_money,
  'assetSlots': Icons.grid_view,
  'knowledgeSlots': Icons.menu_book,
  'monthlySavings': Icons.savings,
  'riskTolerance': Icons.psychology,
  'financialKnowledge': Icons.school,
  'return': Icons.trending_up,
  'volatility': Icons.show_chart,
  'diversification': Icons.pie_chart,
  'sharpeRatio': Icons.bar_chart,
  'managementCostDrag': Icons.percent,
  'liquidityRatio': Icons.water_drop,
  'taxDrag': Icons.receipt_long,
  'emotionalReaction': Icons.psychology,
  'knowledge': Icons.school,
  'investmentHorizonRemaining': Icons.schedule,
  'savingsRate': Icons.savings,
  'behavioralBias': Icons.psychology,
};

class _StoreStatsPanel extends StatelessWidget {
  const _StoreStatsPanel({required this.stats, required this.statSchemas});

  final Map<String, num> stats;
  final List<StatSchema> statSchemas;

  @override
  Widget build(BuildContext context) {
    if (statSchemas.isEmpty) {
      return const SizedBox.shrink();
    }
    final int splitIndex = (statSchemas.length + 1) ~/ 2;
    final List<StatSchema> left = statSchemas.sublist(0, splitIndex);
    final List<StatSchema> right = statSchemas.sublist(splitIndex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final StatSchema stat in left)
                _StatRow(
                  stat: stat,
                  value: stats[stat.id] ?? 0,
                  icon: _statIcons[stat.id],
                ),
            ],
          ),
        ),
        const SizedBox(width: SpacingConstants.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final StatSchema stat in right)
                _StatRow(
                  stat: stat,
                  value: stats[stat.id] ?? 0,
                  icon: _statIcons[stat.id],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PortfolioOverlay extends StatefulWidget {
  const _PortfolioOverlay({
    required this.portfolioButtonKey,
    required this.portfolioHistory,
    required this.currentPortfolioValue,
    required this.currentYear,
    required this.onDismiss,
  });

  final GlobalKey portfolioButtonKey;
  final List<PortfolioHistoryPoint> portfolioHistory;
  final double currentPortfolioValue;
  final int currentYear;
  final VoidCallback onDismiss;

  @override
  State<_PortfolioOverlay> createState() => _PortfolioOverlayState();
}

class _PortfolioOverlayState extends State<_PortfolioOverlay> {
  Offset? _buttonPosition;
  Size? _buttonSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  void _updatePosition() {
    final renderBox =
        widget.portfolioButtonKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _buttonPosition = renderBox.localToGlobal(Offset.zero);
        _buttonSize = renderBox.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: const SizedBox.expand(),
          ),
        ),
        if (_buttonPosition != null && _buttonSize != null) ...[
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              final popupWidth = screenWidth - (SpacingConstants.md * 2);
              const popupHeight = 360.0;
              const left = SpacingConstants.md;
              final top =
                  _buttonPosition!.dy +
                  _buttonSize!.height +
                  SpacingConstants.sm;
              final clampedTop = top.clamp(
                SpacingConstants.md,
                screenHeight - popupHeight - SpacingConstants.md,
              );
              final arrowCenterX =
                  _buttonPosition!.dx + _buttonSize!.width / 2 - left;
              return Positioned(
                left: left,
                top: clampedTop,
                width: popupWidth,
                height: popupHeight,
                child: _PortfolioPopup(
                  portfolioHistory: widget.portfolioHistory,
                  currentPortfolioValue: widget.currentPortfolioValue,
                  currentYear: widget.currentYear,
                  arrowCenterX: arrowCenterX,
                  onDismiss: widget.onDismiss,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PortfolioPopup extends StatelessWidget {
  const _PortfolioPopup({
    required this.portfolioHistory,
    required this.currentPortfolioValue,
    required this.currentYear,
    required this.arrowCenterX,
    required this.onDismiss,
  });

  final List<PortfolioHistoryPoint> portfolioHistory;
  final double currentPortfolioValue;
  final int currentYear;
  final double arrowCenterX;
  final VoidCallback onDismiss;

  List<PortfolioHistoryPoint> _buildDataPoints() {
    final points = List<PortfolioHistoryPoint>.from(portfolioHistory);
    final last = points.isNotEmpty ? points.last : null;
    final shouldAddCurrent =
        last == null ||
        last.value != currentPortfolioValue ||
        last.year != currentYear;
    if (shouldAddCurrent) {
      points.add(
        PortfolioHistoryPoint(year: currentYear, value: currentPortfolioValue),
      );
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final dataPoints = _buildDataPoints();
    final isEmpty = dataPoints.length < 2;
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 12,
            child: CustomPaint(
              painter: ComicTooltipArrowPainter(
                color: GameThemeConstants.creamSurface,
                borderColor: GameThemeConstants.outlineColor,
                arrowCenterX: arrowCenterX,
                pointingDown: false,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(SpacingConstants.md),
            decoration: BoxDecoration(
              color: GameThemeConstants.creamSurface,
              borderRadius: BorderRadius.circular(
                GameThemeConstants.radiusMedium,
              ),
              border: Border.all(
                color: GameThemeConstants.outlineColor,
                width: GameThemeConstants.outlineThickness,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameThemeConstants.outlineColor.withValues(
                    alpha: 0.15,
                  ),
                  offset: const Offset(0, GameThemeConstants.bevelOffset),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Portfolio Evolution',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                        size: 22,
                        color: GameThemeConstants.outlineColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingConstants.md),
                if (isEmpty)
                  _PortfolioEmptyState(currentValue: currentPortfolioValue)
                else
                  PortfolioEvolutionChart(dataPoints: dataPoints),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioEmptyState extends StatelessWidget {
  const _PortfolioEmptyState({required this.currentValue});

  final double currentValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 40,
              color: GameThemeConstants.outlineColorLight,
            ),
            const SizedBox(height: SpacingConstants.sm),
            Text(
              'Play your first simulation to see your portfolio evolution',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GameThemeConstants.outlineColorLight,
              ),
            ),
            const SizedBox(height: SpacingConstants.xs),
            Text(
              'Current: ${currentValue.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: GameThemeConstants.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuySection extends StatelessWidget {
  const _BuySection({
    required this.storeOffer,
    required this.canBuy,
    required this.onPurchase,
    required this.keyForStoreCard,
    required this.onReshuffle,
    required this.reshuffleCost,
    required this.canReshuffle,
    required this.statsSchema,
    required this.remainingAllocationPercent,
    required this.cash,
    required this.storeAssetAllocationPercentPerBuy,
    required this.getStoreAssetPurchaseCashCost,
    required this.onShowStoreAssetEducation,
    required this.layerLinkForStoreOfferSlot,
  });

  final List<StoreItem> storeOffer;
  final bool Function(StoreItem) canBuy;
  final Future<void> Function(
    StoreItem item,
    GlobalKey sourceKey,
    int offerIndex,
  )
  onPurchase;
  final GlobalKey Function(StoreItem item) keyForStoreCard;
  final Future<void> Function() onReshuffle;
  final int reshuffleCost;
  final bool canReshuffle;
  final List<StatSchema> statsSchema;
  final int remainingAllocationPercent;
  final int cash;
  final int storeAssetAllocationPercentPerBuy;
  final int Function(StoreItemAsset asset) getStoreAssetPurchaseCashCost;
  final void Function(
    BuildContext context,
    LayerLink layerLink,
    StoreItemAsset asset,
  )
  onShowStoreAssetEducation;
  final LayerLink Function(int index, StoreItem item) layerLinkForStoreOfferSlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buy Assets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SpacingConstants.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        _allocationChartAssetPath,
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: SpacingConstants.xs),
                      Text(
                        '$remainingAllocationPercent% to allocate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GameThemeConstants.outlineColorLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingConstants.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(_coinAssetPath, width: 20, height: 20),
                      const SizedBox(width: SpacingConstants.xs),
                      Text(
                        '$cash',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GameThemeConstants.outlineColorLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ShuffleButton(
              cost: reshuffleCost,
              canReshuffle: canReshuffle,
              onPressed: onReshuffle,
            ),
          ],
        ),
        const SizedBox(height: SpacingConstants.sm),
        _StoreGrid(
          items: storeOffer,
          canBuy: canBuy,
          onPurchase: onPurchase,
          keyForStoreCard: keyForStoreCard,
          statsSchema: statsSchema,
          storeAssetAllocationPercentPerBuy: storeAssetAllocationPercentPerBuy,
          getStoreAssetPurchaseCashCost: getStoreAssetPurchaseCashCost,
          onShowStoreAssetEducation: onShowStoreAssetEducation,
          layerLinkForStoreOfferSlot: layerLinkForStoreOfferSlot,
        ),
      ],
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({
    required this.cost,
    required this.canReshuffle,
    required this.onPressed,
  });

  final int cost;
  final bool canReshuffle;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final gradient = canReshuffle
        ? [GameThemeConstants.accentLight, GameThemeConstants.accentDark]
        : [Colors.grey.shade400, Colors.grey.shade600];
    final bevelColor = canReshuffle
        ? const Color(0xFF008F82)
        : Colors.grey.shade800;
    return GestureDetector(
      onTap: canReshuffle ? () => onPressed() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingConstants.md,
          vertical: SpacingConstants.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(
            GameThemeConstants.radiusButtonStadium,
          ),
          border: Border.all(
            color: GameThemeConstants.outlineColor,
            width: GameThemeConstants.outlineThickness,
          ),
          boxShadow: [
            BoxShadow(
              color: bevelColor,
              offset: const Offset(0, GameThemeConstants.bevelOffset),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shuffle, color: Colors.white, size: 22),
                const SizedBox(width: SpacingConstants.xs),
                Text(
                  'Shuffle',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(-1, -1),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(1, -1),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: GameThemeConstants.outlineColor,
                        offset: const Offset(-1, 1),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingConstants.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(_coinAssetPath, width: 14, height: 14),
                const SizedBox(width: SpacingConstants.xs),
                Text(
                  '$cost',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreGrid extends StatelessWidget {
  const _StoreGrid({
    required this.items,
    required this.canBuy,
    required this.onPurchase,
    required this.keyForStoreCard,
    required this.statsSchema,
    required this.storeAssetAllocationPercentPerBuy,
    required this.getStoreAssetPurchaseCashCost,
    required this.onShowStoreAssetEducation,
    required this.layerLinkForStoreOfferSlot,
  });

  final List<StoreItem> items;
  final bool Function(StoreItem) canBuy;
  final Future<void> Function(
    StoreItem item,
    GlobalKey sourceKey,
    int offerIndex,
  )
  onPurchase;
  final GlobalKey Function(StoreItem item) keyForStoreCard;
  final List<StatSchema> statsSchema;
  final int storeAssetAllocationPercentPerBuy;
  final int Function(StoreItemAsset asset) getStoreAssetPurchaseCashCost;
  final void Function(
    BuildContext context,
    LayerLink layerLink,
    StoreItemAsset asset,
  )
  onShowStoreAssetEducation;
  final LayerLink Function(int index, StoreItem item) layerLinkForStoreOfferSlot;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingConstants.lg),
        child: Center(
          child: Text(
            'Shelf cleared! Tap shuffle for a fresh set of cards.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GameThemeConstants.outlineColorLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: SpacingConstants.md,
        mainAxisSpacing: SpacingConstants.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final GlobalKey cardKey = keyForStoreCard(item);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(
            key: ValueKey<Object>(
              '${item.runtimeType}_${item.id}_${identityHashCode(item)}',
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.88, end: 1.0),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              ),
              child: KeyedSubtree(
                key: cardKey,
                child: _StoreItemCard(
                  assetLayerLink: item is StoreItemAsset
                      ? layerLinkForStoreOfferSlot(index, item)
                      : null,
                  item: item,
                  canBuy: canBuy(item),
                  onBuy: () {
                    unawaited(onPurchase(item, cardKey, index));
                    return true;
                  },
                  statsSchema: statsSchema,
                  storeAssetAllocationPercentPerBuy:
                      storeAssetAllocationPercentPerBuy,
                  getStoreAssetPurchaseCashCost: getStoreAssetPurchaseCashCost,
                  onShowStoreAssetEducation: onShowStoreAssetEducation,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemSlotsSection extends StatelessWidget {
  const _ItemSlotsSection({
    required this.itemSlotKeys,
    required this.itemSlots,
    required this.statsSchema,
    required this.onCombine,
    required this.canCombine,
  });

  final List<GlobalKey> itemSlotKeys;
  final List<OwnedItem?> itemSlots;
  final List<StatSchema> statsSchema;
  final void Function(int slotA, int slotB) onCombine;
  final bool Function(int slotA, int slotB) canCombine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your Knowledge',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '${itemSlots.where((s) => s != null).length}/${itemSlots.length} slots · '
          'Drag an item onto a similar item of the same level to combine',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: GameThemeConstants.outlineColorLight,
          ),
        ),
        const SizedBox(height: SpacingConstants.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: SpacingConstants.sm,
            mainAxisSpacing: SpacingConstants.sm,
          ),
          itemCount: itemSlots.length,
          itemBuilder: (context, index) {
            final owned = itemSlots[index];
            return KeyedSubtree(
              key: itemSlotKeys[index],
              child: _DraggableItemSlot(
                slotIndex: index,
                owned: owned,
                statsSchema: statsSchema,
                canCombine: canCombine,
                onCombine: onCombine,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DraggableItemSlot extends StatelessWidget {
  const _DraggableItemSlot({
    required this.slotIndex,
    required this.owned,
    required this.statsSchema,
    required this.canCombine,
    required this.onCombine,
  });

  final int slotIndex;
  final OwnedItem? owned;
  final List<StatSchema> statsSchema;
  final bool Function(int slotA, int slotB) canCombine;
  final void Function(int slotA, int slotB) onCombine;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final sourceSlot = details.data;
        return sourceSlot != slotIndex && canCombine(sourceSlot, slotIndex);
      },
      onAcceptWithDetails: (details) {
        final sourceSlot = details.data;
        if (sourceSlot != slotIndex && canCombine(sourceSlot, slotIndex)) {
          onCombine(sourceSlot, slotIndex);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHoveringValidTarget = candidateData.isNotEmpty;
        if (owned != null) {
          return Draggable<int>(
            key: ValueKey('item_slot_$slotIndex'),
            data: slotIndex,
            affinity: Axis.horizontal,
            hitTestBehavior: HitTestBehavior.opaque,
            feedback: _ItemSlotDragFeedback(
              owned: owned!,
              statsSchema: statsSchema,
            ),
            childWhenDragging: Opacity(
              opacity: 0.4,
              child: _ItemSlotCard(
                owned: owned,
                slotIndex: slotIndex,
                statsSchema: statsSchema,
                isSelected: false,
                isHoveringValidTarget: false,
              ),
            ),
            child: _ItemSlotCard(
              owned: owned,
              slotIndex: slotIndex,
              statsSchema: statsSchema,
              isSelected: false,
              isHoveringValidTarget: isHoveringValidTarget,
            ),
          );
        }
        return _ItemSlotCard(
          owned: owned,
          slotIndex: slotIndex,
          statsSchema: statsSchema,
          isSelected: false,
          isHoveringValidTarget: isHoveringValidTarget,
        );
      },
    );
  }
}

class _ItemSlotDragFeedback extends StatelessWidget {
  const _ItemSlotDragFeedback({required this.owned, required this.statsSchema});

  final OwnedItem owned;
  final List<StatSchema> statsSchema;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(SpacingConstants.sm),
        decoration: BoxDecoration(
          color: GameThemeConstants.getItemLevelColor(owned.level),
          borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              owned.icon.toIconData(),
              size: 28,
              color: GameThemeConstants.primaryDark,
            ),
            const SizedBox(height: SpacingConstants.xs),
            Text(
              _formatLearningItemDisplayName(owned.name, owned.level),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemSlotCard extends StatelessWidget {
  const _ItemSlotCard({
    required this.owned,
    required this.slotIndex,
    required this.statsSchema,
    this.isSelected = false,
    this.isHoveringValidTarget = false,
  });

  final OwnedItem? owned;
  final int slotIndex;
  final List<StatSchema> statsSchema;
  final bool isSelected;
  final bool isHoveringValidTarget;

  @override
  Widget build(BuildContext context) {
    final showHighlight = isSelected || isHoveringValidTarget;
    return GameCard(
      backgroundColor: owned != null
          ? GameThemeConstants.getItemLevelColor(owned!.level)
          : null,
      padding: EdgeInsets.all(
        showHighlight ? SpacingConstants.xs : SpacingConstants.md,
      ),
      child: Container(
        decoration: showHighlight
            ? BoxDecoration(
                border: Border.all(
                  color: isHoveringValidTarget
                      ? GameThemeConstants.statPositive
                      : GameThemeConstants.primaryDark,
                  width: GameThemeConstants.outlineThickness,
                ),
                borderRadius: BorderRadius.circular(
                  GameThemeConstants.radiusSmall,
                ),
              )
            : null,
        child: owned == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 28,
                      color: GameThemeConstants.outlineColorLight,
                    ),
                    const SizedBox(height: SpacingConstants.xs),
                    Text(
                      'Empty',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: GameThemeConstants.outlineColorLight,
                      ),
                    ),
                  ],
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      owned!.icon.toIconData(),
                      size: 28,
                      color: GameThemeConstants.primaryDark,
                    ),
                    const SizedBox(height: SpacingConstants.xs),
                    Text(
                      _formatLearningItemDisplayName(owned!.name, owned!.level),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AssetSlotsSection extends StatefulWidget {
  const _AssetSlotsSection({
    required this.assetSectionContentKey,
    required this.getAssetCardKey,
    required this.holdings,
    required this.maxAssetSlots,
    required this.totalAllocatedPercent,
    required this.getAssetAllocationPercent,
    required this.onSell,
    required this.statsSchema,
    required this.getAssetTotalReturnPercent,
  });

  final GlobalKey assetSectionContentKey;
  final GlobalKey Function(String assetId) getAssetCardKey;
  final Map<String, PortfolioAsset> holdings;
  final int maxAssetSlots;
  /// Sum of per-asset allocation labels (each store buy adds 10% to a line).
  final int totalAllocatedPercent;
  final int Function(String assetId) getAssetAllocationPercent;
  final void Function(String assetId) onSell;
  final List<StatSchema> statsSchema;
  final double Function(PortfolioAsset asset) getAssetTotalReturnPercent;

  @override
  State<_AssetSlotsSection> createState() => _AssetSlotsSectionState();
}

class _AssetSlotsSectionState extends State<_AssetSlotsSection> {
  OverlayEntry? _tooltipOverlayEntry;
  final Map<String, LayerLink> _holdingAssetLayerLinks = <String, LayerLink>{};

  LayerLink _layerLinkForHolding(String assetId) {
    return _holdingAssetLayerLinks.putIfAbsent(assetId, LayerLink.new);
  }

  void _showAssetTooltip(BuildContext context, PortfolioAsset asset) {
    _hideAssetTooltip();
    _tooltipOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: _AssetTooltipOverlay(
          layerLink: _layerLinkForHolding(asset.assetId),
          asset: asset,
          statsSchema: widget.statsSchema,
          totalReturnPercent: widget.getAssetTotalReturnPercent(asset),
          onSell: () {
            widget.onSell(asset.assetId);
            _hideAssetTooltip();
          },
          onDismiss: _hideAssetTooltip,
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_tooltipOverlayEntry!);
  }

  void _hideAssetTooltip() {
    _tooltipOverlayEntry?.remove();
    _tooltipOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Assets',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: SpacingConstants.xs),
                  Text(
                    'Up to ${widget.maxAssetSlots} different assets · '
                    '${widget.holdings.length}/${widget.maxAssetSlots} slots used',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.totalAllocatedPercent}% / 100% allocation budget '
                    '(each buy tags 10%; new assets rebalance existing tags)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: GameThemeConstants.outlineColorLight,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              tooltip:
                  'Of course you could diversify more in real life Mr. Buffet',
              icon: Icon(
                Icons.info_outline,
                color: GameThemeConstants.outlineColorLight,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
        const SizedBox(height: SpacingConstants.sm),
        KeyedSubtree(
          key: widget.assetSectionContentKey,
          child: widget.holdings.isEmpty
              ? GameCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(SpacingConstants.lg),
                      child: Text(
                        'No assets yet. Buy from the store above.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GameThemeConstants.outlineColorLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossCount = width > 400 ? 5 : (width > 300 ? 4 : 3);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: SpacingConstants.sm,
                        mainAxisSpacing: SpacingConstants.sm,
                      ),
                      itemCount: widget.holdings.length,
                      itemBuilder: (context, index) {
                        final asset = widget.holdings.values.elementAt(index);
                        final allocationPercent = widget
                            .getAssetAllocationPercent(asset.assetId)
                            .toDouble();
                        return _AssetSlotCard(
                          key: widget.getAssetCardKey(asset.assetId),
                          layerLink: _layerLinkForHolding(asset.assetId),
                          asset: asset,
                          totalReturnPercent: widget.getAssetTotalReturnPercent(
                            asset,
                          ),
                          allocationPercent: allocationPercent,
                          onTap: () => _showAssetTooltip(context, asset),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AssetTooltipOverlay extends StatelessWidget {
  const _AssetTooltipOverlay({
    required this.layerLink,
    required this.asset,
    required this.statsSchema,
    required this.totalReturnPercent,
    required this.onSell,
    required this.onDismiss,
  });

  final LayerLink layerLink;
  final PortfolioAsset asset;
  final List<StatSchema> statsSchema;
  final double totalReturnPercent;
  final VoidCallback onSell;
  final VoidCallback onDismiss;

  String _getStatDisplayName(String statId) {
    return statsSchema
            .where((s) => s.id == statId)
            .map((s) => s.displayName)
            .firstOrNull ??
        statId;
  }

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
          tooltipWidth: 200,
          content: _AssetTooltipContent(
            asset: asset,
            totalReturnPercent: totalReturnPercent,
            getStatDisplayName: _getStatDisplayName,
            onSell: onSell,
            onDismiss: onDismiss,
          ),
        ),
      ],
    );
  }
}

class _AssetTooltipContent extends StatelessWidget {
  const _AssetTooltipContent({
    required this.asset,
    required this.totalReturnPercent,
    required this.getStatDisplayName,
    required this.onSell,
    required this.onDismiss,
  });

  final PortfolioAsset asset;
  final double totalReturnPercent;
  final String Function(String) getStatDisplayName;
  final VoidCallback onSell;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final totalReturnColor = totalReturnPercent >= 0
        ? GameThemeConstants.statPositive
        : GameThemeConstants.statNegative;
    final volatilityColor = GameThemeConstants.statNegative;
    final managementColor = GameThemeConstants.statNegative;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  asset.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
            'Total Return: ${totalReturnPercent >= 0 ? '+' : ''}${totalReturnPercent.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: totalReturnColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SpacingConstants.xs),
          Text(
            '${getStatDisplayName('return')} (expected): ${asset.expectedReturn >= 0 ? '+' : ''}${asset.expectedReturn.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: totalReturnColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SpacingConstants.xs),
          Text(
            '${getStatDisplayName('volatility')}: ${asset.volatility.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: volatilityColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (asset.managementCost > 0) ...[
            const SizedBox(height: SpacingConstants.xs),
            Text(
              '${getStatDisplayName('managementCostDrag')}: -${asset.managementCost.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: managementColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: SpacingConstants.sm),
          GameButton(
            label: 'Sell',
            onPressed: onSell,
            variant: GameButtonVariant.danger,
            isFullWidth: true,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConstants.md,
              vertical: SpacingConstants.sm,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(_coinAssetPath, width: 18, height: 18),
                const SizedBox(width: SpacingConstants.xs),
                Text(
                  asset.totalValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSlotCard extends StatelessWidget {
  const _AssetSlotCard({
    super.key,
    required this.layerLink,
    required this.asset,
    required this.totalReturnPercent,
    required this.allocationPercent,
    required this.onTap,
  });

  final LayerLink layerLink;
  final PortfolioAsset asset;
  final double totalReturnPercent;
  final double allocationPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CompositedTransformTarget(
        link: layerLink,
        child: GameCard(
          padding: const EdgeInsets.all(SpacingConstants.xs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                asset.icon == 'attach_money'
                    ? Image.asset(_coinAssetPath, width: 22, height: 22)
                    : Icon(
                        asset.icon.toIconData(),
                        size: 22,
                        color: GameThemeConstants.primaryDark,
                      ),
                const SizedBox(height: SpacingConstants.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      totalReturnPercent >= 0
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      size: 16,
                      color: totalReturnPercent >= 0
                          ? GameThemeConstants.statPositive
                          : GameThemeConstants.statNegative,
                    ),
                    Text(
                      '${totalReturnPercent >= 0 ? '+' : ''}${totalReturnPercent.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: totalReturnPercent >= 0
                            ? GameThemeConstants.statPositive
                            : GameThemeConstants.statNegative,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${allocationPercent.toStringAsFixed(0)}% alloc.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: GameThemeConstants.outlineColorLight,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatefulWidget {
  const _StatRow({required this.stat, required this.value, this.icon});

  static const Duration _tooltipShowDuration = Duration(seconds: 5);

  final StatSchema stat;
  final num value;
  final IconData? icon;

  @override
  State<_StatRow> createState() => _StatRowState();
}

class _StatRowState extends State<_StatRow> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  Color _getStatColor() {
    if (widget.value > 0) return GameThemeConstants.statPositive;
    if (widget.value < 0) return GameThemeConstants.statNegative;
    return GameThemeConstants.statNeutral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatColor();
    final TextStyle? tooltipBodyStyle = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: GameThemeConstants.creamSurface, height: 1.35);
    final String description = widget.stat.description.trim();
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingConstants.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(widget.icon, size: 18, color: color),
            ),
            const SizedBox(width: SpacingConstants.xs),
          ],
          Expanded(
            child: Text(
              widget.stat.displayName,
              style: TextStyle(color: color),
            ),
          ),
          Text(
            widget.value == widget.value.roundToDouble()
                ? widget.value.toStringAsFixed(0)
                : widget.value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
    if (description.isEmpty) {
      return row;
    }
    return Tooltip(
      key: _tooltipKey,
      triggerMode: TooltipTriggerMode.manual,
      showDuration: _StatRow._tooltipShowDuration,
      padding: const EdgeInsets.all(SpacingConstants.sm),
      margin: const EdgeInsets.symmetric(horizontal: SpacingConstants.md),
      decoration: BoxDecoration(
        color: GameThemeConstants.darkNavy,
        borderRadius: BorderRadius.circular(SpacingConstants.radiusSm),
      ),
      textStyle: tooltipBodyStyle,
      message: description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
          borderRadius: BorderRadius.circular(SpacingConstants.radiusSm),
          mouseCursor: SystemMouseCursors.click,
          child: row,
        ),
      ),
    );
  }
}

class _StoreInvestCostTrailing extends StatelessWidget {
  const _StoreInvestCostTrailing({
    required this.allocationPercent,
    required this.cashCost,
    required this.compact,
  });

  final int allocationPercent;
  final int cashCost;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double chartSize = compact ? 12 : 16;
    final double coinSize = compact ? 12 : 16;
    final double fontSize = compact ? 11 : 14;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _allocationChartAssetPath,
          width: chartSize,
          height: chartSize,
        ),
        Text(
          '$allocationPercent',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: SpacingConstants.xs),
        Image.asset(_coinAssetPath, width: coinSize, height: coinSize),
        Text(
          '$cashCost',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

class _AnimatedInvestButton extends StatefulWidget {
  const _AnimatedInvestButton({
    required this.canBuy,
    required this.onBuy,
    required this.allocationPercent,
    required this.cashCost,
    this.compact = false,
  });

  final bool canBuy;
  final bool compact;
  final bool Function() onBuy;
  final int allocationPercent;
  final int cashCost;

  @override
  State<_AnimatedInvestButton> createState() => _AnimatedInvestButtonState();
}

class _AnimatedInvestButtonState extends State<_AnimatedInvestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.canBuy) return;
    final ok = widget.onBuy();
    if (ok) {
      _controller.forward().then((_) {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IgnorePointer(
          child: GameButton(
            label: 'Invest',
            onPressed: widget.canBuy ? () {} : null,
            variant: GameButtonVariant.success,
            isFullWidth: !widget.compact,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact
                  ? SpacingConstants.xs
                  : SpacingConstants.sm,
              vertical: widget.compact ? 3 : 4,
            ),
            trailing: _StoreInvestCostTrailing(
              allocationPercent: widget.allocationPercent,
              cashCost: widget.cashCost,
              compact: widget.compact,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.assetLayerLink,
    required this.item,
    required this.canBuy,
    required this.onBuy,
    required this.statsSchema,
    required this.storeAssetAllocationPercentPerBuy,
    required this.getStoreAssetPurchaseCashCost,
    required this.onShowStoreAssetEducation,
  });

  /// Layer link for [CompositedTransformTarget]; null for knowledge items.
  final LayerLink? assetLayerLink;
  final StoreItem item;
  final bool canBuy;
  final bool Function() onBuy;
  final List<StatSchema> statsSchema;
  final int storeAssetAllocationPercentPerBuy;
  final int Function(StoreItemAsset asset) getStoreAssetPurchaseCashCost;
  final void Function(
    BuildContext context,
    LayerLink layerLink,
    StoreItemAsset asset,
  )
  onShowStoreAssetEducation;

  String _getStatDisplayName(String statId) {
    return statsSchema
            .where((s) => s.id == statId)
            .map((s) => s.displayName)
            .firstOrNull ??
        statId;
  }

  Color _getCardBackgroundColor() {
    if (item is StoreItemAsset) {
      return GameThemeConstants.creamSurface;
    }
    return GameThemeConstants.getItemLevelColor((item as StoreItemItem).level);
  }

  @override
  Widget build(BuildContext context) {
    final card = GameCard(
      backgroundColor: _getCardBackgroundColor(),
      padding: const EdgeInsets.all(SpacingConstants.sm),
      child: _buildCardLayout(context),
    );
    final link = assetLayerLink;
    if (link != null) {
      return CompositedTransformTarget(link: link, child: card);
    }
    return card;
  }

  Widget _buildCardLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.8,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: item.icon == 'attach_money'
                    ? Image.asset(_coinAssetPath, width: 40, height: 40)
                    : Icon(
                        item.icon.toIconData(),
                        size: 80,
                        color: GameThemeConstants.primaryDark,
                      ),
              ),
              if (item case final StoreItemAsset storeAsset)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final l = assetLayerLink;
                        if (l != null) {
                          onShowStoreAssetEducation(context, l, storeAsset);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: GameThemeConstants.creamSurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: GameThemeConstants.outlineColor,
                            width: GameThemeConstants.outlineThicknessSmall,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GameThemeConstants.outlineColor.withValues(
                                alpha: 0.12,
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: GameThemeConstants.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  switch (item) {
                    StoreItemItem(:final name, :final level) =>
                      _formatLearningItemDisplayName(name, level),
                    _ => item.name,
                  },
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: SpacingConstants.xs),
                _buildStatsContent(context),
              ],
            ),
          ),
        ),
        _buildButton(context),
        const SizedBox(height: SpacingConstants.sm),
      ],
    );
  }

  Widget _buildStatsContent(BuildContext context) {
    return switch (item) {
      StoreItemItem(:final statEffects) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: statEffects.entries
            .where((e) => e.key != 'money')
            .map(
              (e) => Text(
                '${_getStatDisplayName(e.key)}: ${e.value > 0 ? '+' : ''}${e.value.toStringAsFixed(e.value == e.value.roundToDouble() ? 0 : 1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: e.value > 0
                      ? GameThemeConstants.statPositive
                      : e.value < 0
                      ? GameThemeConstants.statNegative
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
            .toList(),
      ),
      StoreItemAsset(
        :final expectedReturn,
        :final volatility,
        :final managementCost,
      ) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_getStatDisplayName('return')}: ${expectedReturn >= 0 ? '+' : ''}${expectedReturn.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: expectedReturn > 0
                    ? GameThemeConstants.statPositive
                    : expectedReturn < 0
                    ? GameThemeConstants.statNegative
                    : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_getStatDisplayName('volatility')}: ${volatility.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: volatility > 0
                    ? GameThemeConstants.statPositive
                    : volatility < 0
                    ? GameThemeConstants.statNegative
                    : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (managementCost > 0)
              Text(
                '${_getStatDisplayName('managementCostDrag')}: -${managementCost.toStringAsFixed(2)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: GameThemeConstants.statNegative,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
    };
  }

  Widget _buildButton(BuildContext context) {
    final StoreItem currentItem = item;
    if (currentItem is StoreItemAsset) {
      return _AnimatedInvestButton(
        canBuy: canBuy,
        onBuy: onBuy,
        compact: false,
        allocationPercent: storeAssetAllocationPercentPerBuy,
        cashCost: getStoreAssetPurchaseCashCost(currentItem),
      );
    }
    return GameButton(
      label: 'Buy',
      onPressed: canBuy ? onBuy : null,
      variant: GameButtonVariant.success,
      isFullWidth: true,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.sm,
        vertical: SpacingConstants.xs,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(_coinAssetPath, width: 20, height: 20),
          const SizedBox(width: SpacingConstants.xs),
          Text(
            '${item.price}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
