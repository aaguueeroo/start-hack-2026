import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/portfolio_evolution_chart.dart';
import 'package:start_hack_2026/core/widgets/game_key_factors_bar.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

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

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final GlobalKey _statsButtonKey = GlobalKey();
  final GlobalKey _portfolioButtonKey = GlobalKey();
  OverlayEntry? _statsOverlayEntry;
  OverlayEntry? _portfolioOverlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().loadStoreData();
    });
  }

  void _showStatsOverlay(BuildContext context, StoreController controller) {
    _hideStatsOverlay();
    _statsOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: _StatsOverlay(
          statsButtonKey: _statsButtonKey,
          stats: controller.stats,
          schema: controller.statsSchema,
          onDismiss: _hideStatsOverlay,
        ),
      ),
    );
    Overlay.of(context).insert(_statsOverlayEntry!);
  }

  void _hideStatsOverlay() {
    _statsOverlayEntry?.remove();
    _statsOverlayEntry = null;
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
    Overlay.of(context).insert(_portfolioOverlayEntry!);
  }

  void _hidePortfolioOverlay() {
    _portfolioOverlayEntry?.remove();
    _portfolioOverlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Store'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              GestureDetector(
                onLongPressDown: (_) =>
                    _showPortfolioOverlay(context, controller),
                onLongPressUp: _hidePortfolioOverlay,
                onLongPressCancel: _hidePortfolioOverlay,
                child: SizedBox(
                  key: _portfolioButtonKey,
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.show_chart),
                    onPressed: () {},
                  ),
                ),
              ),
              GestureDetector(
                onLongPressDown: (_) => _showStatsOverlay(context, controller),
                onLongPressUp: _hideStatsOverlay,
                onLongPressCancel: _hideStatsOverlay,
                child: SizedBox(
                  key: _statsButtonKey,
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.bar_chart),
                    onPressed: () {},
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bug_report),
                onPressed: () => context.push('/simulation-debug'),
                tooltip: 'Debug',
              ),
            ],
          ),
          body: Container(
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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(SpacingConstants.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GameKeyFactorsBar(stats: controller.stats),
                        _BuySection(
                          storeOffer: controller.storeOffer,
                          canBuy: controller.canBuy,
                          onPurchase: controller.purchase,
                          statsSchema: controller.statsSchema,
                          totalCapital: controller.currentPortfolioValue,
                          baselineValue: _getBaselineValueForComparison(
                            controller,
                          ),
                          remainingAllocationPercent:
                              controller.remainingAllocationPercent,
                        ),
                        const SizedBox(height: SpacingConstants.lg),
                        _ItemSlotsSection(
                          itemSlots: controller.itemSlots,
                          statsSchema: controller.statsSchema,
                          onCombine: controller.combineItems,
                          canCombine: controller.canCombineItems,
                        ),
                        const SizedBox(height: SpacingConstants.lg),
                        _AssetSlotsSection(
                          holdings: controller.holdings,
                          currentPortfolioValue: controller.currentPortfolioValue,
                          onSell: controller.sellAsset,
                          statsSchema: controller.statsSchema,
                          getAssetTotalReturnPercent:
                              controller.getAssetTotalReturnPercent,
                        ),
                        const SizedBox(height: SpacingConstants.xl),
                        GameButton(
                          label: 'Play',
                          icon: Icons.play_arrow,
                          onPressed: () => context.push('/simulation'),
                          variant: GameButtonVariant.success,
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

class _StatsOverlay extends StatefulWidget {
  const _StatsOverlay({
    required this.statsButtonKey,
    required this.stats,
    required this.schema,
    required this.onDismiss,
  });

  final GlobalKey statsButtonKey;
  final Map<String, num> stats;
  final List<StatSchema> schema;
  final VoidCallback onDismiss;

  @override
  State<_StatsOverlay> createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<_StatsOverlay> {
  Offset? _buttonPosition;
  Size? _buttonSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  void _updatePosition() {
    final renderBox =
        widget.statsButtonKey.currentContext?.findRenderObject() as RenderBox?;
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
          child: Listener(
            onPointerUp: (_) => widget.onDismiss(),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        if (_buttonPosition != null && _buttonSize != null) ...[
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final popupWidth = screenWidth - (SpacingConstants.md * 2);
              const left = SpacingConstants.md;
              final arrowCenterX =
                  _buttonPosition!.dx + _buttonSize!.width / 2 - left;
              return Positioned(
                left: left,
                top:
                    _buttonPosition!.dy +
                    _buttonSize!.height +
                    SpacingConstants.sm,
                width: popupWidth,
                child: _StatsPopup(
                  stats: widget.stats,
                  schema: widget.schema,
                  arrowCenterX: arrowCenterX,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

const _statIcons = <String, IconData>{
  'money': Icons.attach_money,
  'assetSlots': Icons.grid_view,
  'monthlySavings': Icons.savings,
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

class _StatsPopup extends StatelessWidget {
  const _StatsPopup({
    required this.stats,
    required this.schema,
    required this.arrowCenterX,
  });

  final Map<String, num> stats;
  final List<StatSchema> schema;
  final double arrowCenterX;

  @override
  Widget build(BuildContext context) {
    final portfolioStats = schema
        .where(
          (s) =>
              stats.containsKey(s.id) &&
              s.id != 'money' &&
              s.category == 'portfolio',
        )
        .toList();
    final personalStats = schema
        .where(
          (s) =>
              stats.containsKey(s.id) &&
              s.id != 'money' &&
              s.category == 'personal',
        )
        .toList();
    final displayStats = [...portfolioStats, ...personalStats];
    if (displayStats.isEmpty) {
      return Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 12,
              child: CustomPaint(
                painter: _TooltipArrowPainter(
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
              child: Text(
                'No stats to display',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GameThemeConstants.outlineColorLight,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 12,
            child: CustomPaint(
              painter: _TooltipArrowPainter(
                color: GameThemeConstants.creamSurface,
                borderColor: GameThemeConstants.outlineColor,
                arrowCenterX: arrowCenterX,
                pointingDown: false,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: SpacingConstants.lg,
              horizontal: SpacingConstants.lg,
            ),
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
                Text(
                  'Stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: SpacingConstants.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (portfolioStats.isNotEmpty) ...[
                            Text(
                              'Portfolio',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            ...portfolioStats.map(
                              (stat) => _StatRow(
                                stat: stat,
                                value: stats[stat.id] ?? 0,
                                icon: _statIcons[stat.id],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: SpacingConstants.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (personalStats.isNotEmpty) ...[
                            Text(
                              'Personal',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            ...personalStats.map(
                              (stat) => _StatRow(
                                stat: stat,
                                value: stats[stat.id] ?? 0,
                                icon: _statIcons[stat.id],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
          child: Listener(
            onPointerUp: (_) => widget.onDismiss(),
            behavior: HitTestBehavior.translucent,
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
  });

  final List<PortfolioHistoryPoint> portfolioHistory;
  final double currentPortfolioValue;
  final int currentYear;
  final double arrowCenterX;

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
              painter: _TooltipArrowPainter(
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
                Text(
                  'Portfolio Evolution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              'Current: \$${currentValue.toStringAsFixed(0)}',
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
    required this.statsSchema,
    required this.totalCapital,
    required this.baselineValue,
    required this.remainingAllocationPercent,
  });

  final List<StoreItem> storeOffer;
  final bool Function(StoreItem) canBuy;
  final void Function(StoreItem item) onPurchase;
  final List<StatSchema> statsSchema;
  final double totalCapital;
  final double? baselineValue;
  final int remainingAllocationPercent;

  @override
  Widget build(BuildContext context) {
    final hasComparison = baselineValue != null;
    final diff = hasComparison ? totalCapital - baselineValue! : 0.0;
    final isGrowing = diff > 0;
    final isDecreasing = diff < 0;
    final valueColor = isGrowing
        ? GameThemeConstants.statPositive
        : isDecreasing
        ? GameThemeConstants.statNegative
        : GameThemeConstants.primaryDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
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
              const SizedBox(height: SpacingConstants.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasComparison) ...[
                    Icon(
                      isGrowing
                          ? Icons.arrow_drop_up
                          : isDecreasing
                          ? Icons.arrow_drop_down
                          : Icons.remove,
                      size: 48,
                      color: valueColor,
                    ),
                    const SizedBox(width: SpacingConstants.xs),
                  ],
                  Text(
                    '\$${totalCapital.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingConstants.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Buy Assets',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    color: GameThemeConstants.warningLight,
                    size: 24,
                  ),
                  const SizedBox(width: SpacingConstants.sm),
                  Flexible(
                    child: Text(
                      '$remainingAllocationPercent% to allocate',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingConstants.sm),
        _StoreGrid(
          items: storeOffer,
          canBuy: canBuy,
          onPurchase: (item) => onPurchase(item),
          statsSchema: statsSchema,
        ),
      ],
    );
  }
}

class _StoreGrid extends StatelessWidget {
  const _StoreGrid({
    required this.items,
    required this.canBuy,
    required this.onPurchase,
    required this.statsSchema,
  });

  final List<StoreItem> items;
  final bool Function(StoreItem) canBuy;
  final void Function(StoreItem item) onPurchase;
  final List<StatSchema> statsSchema;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: SpacingConstants.md,
        mainAxisSpacing: SpacingConstants.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StoreItemCard(
          item: item,
          canBuy: canBuy(item),
          onBuy: () => onPurchase(item),
          statsSchema: statsSchema,
        );
      },
    );
  }
}

class _ItemSlotsSection extends StatelessWidget {
  const _ItemSlotsSection({
    required this.itemSlots,
    required this.statsSchema,
    required this.onCombine,
    required this.canCombine,
  });

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
            childAspectRatio: 1.1,
            crossAxisSpacing: SpacingConstants.sm,
            mainAxisSpacing: SpacingConstants.sm,
          ),
          itemCount: itemSlots.length,
          itemBuilder: (context, index) {
            final owned = itemSlots[index];
            return _DraggableItemSlot(
              slotIndex: index,
              owned: owned,
              statsSchema: statsSchema,
              canCombine: canCombine,
              onCombine: onCombine,
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
              'L${owned.level}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
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
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: GameThemeConstants.outlineColorLight,
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
                      'L${owned!.level}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      owned!.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
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
    required this.holdings,
    required this.currentPortfolioValue,
    required this.onSell,
    required this.statsSchema,
    required this.getAssetTotalReturnPercent,
  });

  final Map<String, PortfolioAsset> holdings;
  final double currentPortfolioValue;
  final void Function(String assetId) onSell;
  final List<StatSchema> statsSchema;
  final double Function(PortfolioAsset asset) getAssetTotalReturnPercent;

  @override
  State<_AssetSlotsSection> createState() => _AssetSlotsSectionState();
}

class _AssetSlotsSectionState extends State<_AssetSlotsSection> {
  final Map<String, GlobalKey> _cardKeys = {};
  OverlayEntry? _tooltipOverlayEntry;

  GlobalKey _getKeyForAsset(String assetId) {
    _cardKeys[assetId] ??= GlobalKey();
    return _cardKeys[assetId]!;
  }

  void _showAssetTooltip(BuildContext context, PortfolioAsset asset) {
    _hideAssetTooltip();
    final cardKey = _getKeyForAsset(asset.assetId);
    _tooltipOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned.fill(
        child: _AssetTooltipOverlay(
          cardKey: cardKey,
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
    Overlay.of(context).insert(_tooltipOverlayEntry!);
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
        Text(
          'Your Assets',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: SpacingConstants.sm),
        if (widget.holdings.isEmpty)
          GameCard(
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
        else
          LayoutBuilder(
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
              final allocationPercent = widget.currentPortfolioValue > 0
                  ? (asset.totalValue / widget.currentPortfolioValue) * 100
                  : 0.0;
              return _AssetSlotCard(
                key: _getKeyForAsset(asset.assetId),
                asset: asset,
                totalReturnPercent: widget.getAssetTotalReturnPercent(asset),
                allocationPercent: allocationPercent,
                onTap: () => _showAssetTooltip(context, asset),
              );
            },
          );
            },
          ),
      ],
    );
  }
}

class _AssetTooltipOverlay extends StatefulWidget {
  const _AssetTooltipOverlay({
    required this.cardKey,
    required this.asset,
    required this.statsSchema,
    required this.totalReturnPercent,
    required this.onSell,
    required this.onDismiss,
  });

  final GlobalKey cardKey;
  final PortfolioAsset asset;
  final List<StatSchema> statsSchema;
  final double totalReturnPercent;
  final VoidCallback onSell;
  final VoidCallback onDismiss;

  @override
  State<_AssetTooltipOverlay> createState() => _AssetTooltipOverlayState();
}

class _AssetTooltipOverlayState extends State<_AssetTooltipOverlay> {
  Offset? _cardPosition;
  Size? _cardSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  void _updatePosition() {
    final renderBox =
        widget.cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _cardPosition = renderBox.localToGlobal(Offset.zero);
        _cardSize = renderBox.size;
      });
    }
  }

  String _getStatDisplayName(String statId) {
    return widget.statsSchema
            .where((s) => s.id == statId)
            .map((s) => s.displayName)
            .firstOrNull ??
        statId;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerUp: (_) => widget.onDismiss(),
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        if (_cardPosition != null && _cardSize != null)
          _AssetTooltipPopup(
            cardPosition: _cardPosition!,
            cardSize: _cardSize!,
            asset: widget.asset,
            totalReturnPercent: widget.totalReturnPercent,
            getStatDisplayName: _getStatDisplayName,
            onSell: widget.onSell,
          ),
      ],
    );
  }
}

class _AssetTooltipPopup extends StatelessWidget {
  const _AssetTooltipPopup({
    required this.cardPosition,
    required this.cardSize,
    required this.asset,
    required this.totalReturnPercent,
    required this.getStatDisplayName,
    required this.onSell,
  });

  final Offset cardPosition;
  final Size cardSize;
  final PortfolioAsset asset;
  final double totalReturnPercent;
  final String Function(String) getStatDisplayName;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    const tooltipWidth = 200.0;
    const arrowHeight = 12.0;
    const spacing = SpacingConstants.sm;
    final cardCenterX = cardPosition.dx + cardSize.width / 2;
    var tooltipLeft = cardCenterX - tooltipWidth / 2;
    tooltipLeft = tooltipLeft.clamp(
      SpacingConstants.md,
      MediaQuery.of(context).size.width - tooltipWidth - SpacingConstants.md,
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
              _AssetTooltipContent(
                asset: asset,
                totalReturnPercent: totalReturnPercent,
                getStatDisplayName: getStatDisplayName,
                onSell: onSell,
              ),
              CustomPaint(
                size: Size(tooltipWidth, arrowHeight),
                painter: _TooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowCenterX,
                  pointingDown: true,
                ),
              ),
            ] else ...[
              CustomPaint(
                size: Size(tooltipWidth, arrowHeight),
                painter: _TooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowCenterX,
                  pointingDown: false,
                ),
              ),
              _AssetTooltipContent(
                asset: asset,
                totalReturnPercent: totalReturnPercent,
                getStatDisplayName: getStatDisplayName,
                onSell: onSell,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  _TooltipArrowPainter({
    required this.color,
    required this.borderColor,
    required this.arrowCenterX,
    required this.pointingDown,
  });

  final Color color;
  final Color borderColor;
  final double arrowCenterX;
  final bool pointingDown;

  @override
  void paint(Canvas canvas, Size size) {
    const arrowWidth = 16.0;
    final path = Path();
    if (pointingDown) {
      path.moveTo(arrowCenterX - arrowWidth / 2, 0);
      path.lineTo(arrowCenterX + arrowWidth / 2, 0);
      path.lineTo(arrowCenterX, size.height);
      path.close();
    } else {
      path.moveTo(arrowCenterX - arrowWidth / 2, size.height);
      path.lineTo(arrowCenterX + arrowWidth / 2, size.height);
      path.lineTo(arrowCenterX, 0);
      path.close();
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameThemeConstants.outlineThickness,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AssetTooltipContent extends StatelessWidget {
  const _AssetTooltipContent({
    required this.asset,
    required this.totalReturnPercent,
    required this.getStatDisplayName,
    required this.onSell,
  });

  final PortfolioAsset asset;
  final double totalReturnPercent;
  final String Function(String) getStatDisplayName;
  final VoidCallback onSell;

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
                Icon(
                  Icons.monetization_on,
                  size: 18,
                  color: GameThemeConstants.warningLight,
                ),
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
    required this.asset,
    required this.totalReturnPercent,
    required this.allocationPercent,
    required this.onTap,
  });

  final PortfolioAsset asset;
  final double totalReturnPercent;
  final double allocationPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GameCard(
        padding: const EdgeInsets.all(SpacingConstants.xs),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
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
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.value, this.icon});

  final StatSchema stat;
  final num value;
  final IconData? icon;

  Color _getStatColor() {
    if (value > 0) return GameThemeConstants.statPositive;
    if (value < 0) return GameThemeConstants.statNegative;
    return GameThemeConstants.statNeutral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatColor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingConstants.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: SpacingConstants.xs),
          ],
          Expanded(
            child: Text(stat.displayName, style: TextStyle(color: color)),
          ),
          Text(
            value == value.roundToDouble()
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInvestButton extends StatefulWidget {
  const _AnimatedInvestButton({
    required this.canBuy,
    required this.onBuy,
  });

  final bool canBuy;
  final VoidCallback onBuy;

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.canBuy) return;
    widget.onBuy();
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
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
            isFullWidth: true,
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingConstants.sm,
              vertical: SpacingConstants.xs,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: GameThemeConstants.warningLight,
                ),
                const SizedBox(width: SpacingConstants.xs),
                const Text(
                  '10%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.canBuy,
    required this.onBuy,
    required this.statsSchema,
  });

  final StoreItem item;
  final bool canBuy;
  final VoidCallback onBuy;
  final List<StatSchema> statsSchema;

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
    return GameCard(
      backgroundColor: _getCardBackgroundColor(),
      padding: const EdgeInsets.all(SpacingConstants.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    item.icon.toIconData(),
                    size: 28,
                    color: GameThemeConstants.primaryDark,
                  ),
                ),
                if (item is StoreItemItem)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingConstants.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: GameThemeConstants.primaryDark,
                        borderRadius: BorderRadius.circular(
                          GameThemeConstants.radiusSmall,
                        ),
                      ),
                      child: Text(
                        'L${(item as StoreItemItem).level}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
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
                    item.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SpacingConstants.xs),
                  switch (item) {
                    StoreItemItem(:final statEffects) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: statEffects.entries
                            .where((e) => e.key != 'money')
                            .map(
                              (e) => Text(
                                '${_getStatDisplayName(e.key)}: ${e.value > 0 ? '+' : ''}${e.value.toStringAsFixed(e.value == e.value.roundToDouble() ? 0 : 1)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
                            'Ret: ${expectedReturn.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Vol: ${volatility.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (managementCost > 0)
                            Text(
                              'Mgmt: ${managementCost.toStringAsFixed(2)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                  },
                ],
              ),
            ),
          ),
          item is StoreItemAsset
              ? _AnimatedInvestButton(
                  canBuy: canBuy,
                  onBuy: onBuy,
                )
              : GameButton(
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
                      Icon(
                        Icons.monetization_on,
                        size: 20,
                        color: GameThemeConstants.warningLight,
                      ),
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
                ),
        ],
      ),
    );
  }
}
