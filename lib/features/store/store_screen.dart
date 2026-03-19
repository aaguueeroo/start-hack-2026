import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/domain/entities/owned_item.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/engine/calculation_engine.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';
import 'package:widget_tooltip/widget_tooltip.dart';

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
              Padding(
                padding: const EdgeInsets.only(right: SpacingConstants.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: GameThemeConstants.warningLight,
                      size: 24,
                    ),
                    const SizedBox(width: SpacingConstants.sm),
                    Text(
                      '${controller.cash}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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
                    tooltip: 'Hold to view portfolio evolution',
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
                    tooltip: 'Hold to view stats',
                  ),
                ),
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
                        _BuySection(
                          storeOffer: controller.storeOffer,
                          canBuy: controller.canBuy,
                          onPurchase: (item, index) =>
                              controller.purchase(item, replaceAtIndex: index),
                          statsSchema: controller.statsSchema,
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
                          onSell: controller.sellAsset,
                          statsSchema: controller.statsSchema,
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
              return Positioned(
                left: left,
                top:
                    _buttonPosition!.dy +
                    _buttonSize!.height +
                    SpacingConstants.sm,
                width: popupWidth,
                child: _StatsPopup(stats: widget.stats, schema: widget.schema),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _StatsPopup extends StatelessWidget {
  const _StatsPopup({required this.stats, required this.schema});

  final Map<String, num> stats;
  final List<StatSchema> schema;

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
            CustomPaint(
              size: const Size(24, 12),
              painter: _PeakPainter(
                color: GameThemeConstants.creamSurface,
                borderColor: GameThemeConstants.outlineColor,
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
          CustomPaint(
            size: const Size(24, 12),
            painter: _PeakPainter(
              color: GameThemeConstants.creamSurface,
              borderColor: GameThemeConstants.outlineColor,
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
                  'Stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            ...portfolioStats.map(
                              (stat) => _StatRow(
                                stat: stat,
                                value: stats[stat.id] ?? 0,
                                showInfoTooltip: false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (personalStats.isNotEmpty) ...[
                            Text(
                              'Personal',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: SpacingConstants.xs),
                            ...personalStats.map(
                              (stat) => _StatRow(
                                stat: stat,
                                value: stats[stat.id] ?? 0,
                                showInfoTooltip: false,
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
              return Positioned(
                left: left,
                top: clampedTop,
                width: popupWidth,
                height: popupHeight,
                child: _PortfolioPopup(
                  portfolioHistory: widget.portfolioHistory,
                  currentPortfolioValue: widget.currentPortfolioValue,
                  currentYear: widget.currentYear,
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
  });

  final List<PortfolioHistoryPoint> portfolioHistory;
  final double currentPortfolioValue;
  final int currentYear;

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
          CustomPaint(
            size: const Size(24, 12),
            painter: _PeakPainter(
              color: GameThemeConstants.creamSurface,
              borderColor: GameThemeConstants.outlineColor,
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
                  _PortfolioChart(dataPoints: dataPoints),
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

class _PortfolioChart extends StatelessWidget {
  const _PortfolioChart({required this.dataPoints});

  final List<PortfolioHistoryPoint> dataPoints;

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();
    final values = dataPoints.map((p) => p.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    var minY = (minVal * 0.95).clamp(0.0, double.infinity).toDouble();
    var maxY = (maxVal * 1.05).toDouble();
    if (maxY <= minY) maxY = minY + 1;
    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (dataPoints.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: GameThemeConstants.primaryDark,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: GameThemeConstants.primaryDark,
                      strokeWidth: GameThemeConstants.outlineThicknessSmall,
                      strokeColor: GameThemeConstants.outlineColor,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: GameThemeConstants.primaryDark.withValues(alpha: 0.2),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: GameThemeConstants.outlineColor,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index >= 0 && index < dataPoints.length) {
                    return Text(
                      'Y${dataPoints[index].year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: GameThemeConstants.outlineColor,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: GameThemeConstants.outlineColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: GameThemeConstants.outlineColor.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: GameThemeConstants.outlineColor,
              width: GameThemeConstants.outlineThicknessSmall,
            ),
          ),
        ),
        duration: const Duration(milliseconds: 150),
      ),
    );
  }
}

class _PeakPainter extends CustomPainter {
  _PeakPainter({required this.color, required this.borderColor});

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
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

class _BuySection extends StatelessWidget {
  const _BuySection({
    required this.storeOffer,
    required this.canBuy,
    required this.onPurchase,
    required this.statsSchema,
  });

  final List<StoreItem> storeOffer;
  final bool Function(StoreItem) canBuy;
  final void Function(StoreItem item, int index) onPurchase;
  final List<StatSchema> statsSchema;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Buy Assets',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: SpacingConstants.sm),
        _StoreGrid(
          items: storeOffer,
          canBuy: canBuy,
          onPurchase: onPurchase,
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
  final void Function(StoreItem item, int index) onPurchase;
  final List<StatSchema> statsSchema;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: SpacingConstants.md,
        mainAxisSpacing: SpacingConstants.md,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _StoreItemCard(
          item: item,
          canBuy: canBuy(item),
          onBuy: () => onPurchase(item, index),
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
            childAspectRatio: 1,
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    owned!.icon.toIconData(),
                    size: 36,
                    color: GameThemeConstants.primaryDark,
                  ),
                  const SizedBox(height: SpacingConstants.xs),
                  Text(
                    'L${owned!.level}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    owned!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AssetSlotsSection extends StatefulWidget {
  const _AssetSlotsSection({
    required this.holdings,
    required this.onSell,
    required this.statsSchema,
  });

  final Map<String, PortfolioAsset> holdings;
  final void Function(String assetId) onSell;
  final List<StatSchema> statsSchema;

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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: SpacingConstants.sm,
              mainAxisSpacing: SpacingConstants.sm,
            ),
            itemCount: widget.holdings.length,
            itemBuilder: (context, index) {
              final asset = widget.holdings.values.elementAt(index);
              return _AssetSlotCard(
                key: _getKeyForAsset(asset.assetId),
                asset: asset,
                onTap: () => _showAssetTooltip(context, asset),
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
    required this.onSell,
    required this.onDismiss,
  });

  final GlobalKey cardKey;
  final PortfolioAsset asset;
  final List<StatSchema> statsSchema;
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
    required this.getStatDisplayName,
    required this.onSell,
  });

  final Offset cardPosition;
  final Size cardSize;
  final PortfolioAsset asset;
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
    const estimatedTooltipHeight = 220.0;
    final showAbove = cardPosition.dy > screenHeight / 2;
    final tooltipTop = showAbove
        ? (cardPosition.dy - spacing - estimatedTooltipHeight).clamp(
            SpacingConstants.md,
            screenHeight - estimatedTooltipHeight,
          )
        : cardPosition.dy + cardSize.height + spacing;
    return Positioned(
      left: tooltipLeft,
      top: showAbove ? tooltipTop : tooltipTop,
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
    required this.getStatDisplayName,
    required this.onSell,
  });

  final PortfolioAsset asset;
  final String Function(String) getStatDisplayName;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final returnColor = asset.expectedReturn >= 0
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
            '${getStatDisplayName('return')}: ${asset.expectedReturn >= 0 ? '+' : ''}${asset.expectedReturn.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: returnColor,
              fontWeight: FontWeight.w600,
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
  const _AssetSlotCard({super.key, required this.asset, required this.onTap});

  final PortfolioAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gainLoss = asset.gainLossPercent;
    return GestureDetector(
      onTap: onTap,
      child: GameCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              asset.icon.toIconData(),
              size: 24,
              color: GameThemeConstants.primaryDark,
            ),
            const SizedBox(height: SpacingConstants.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  gainLoss >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 18,
                  color: gainLoss >= 0
                      ? GameThemeConstants.statPositive
                      : GameThemeConstants.statNegative,
                ),
                Text(
                  '${gainLoss >= 0 ? '+' : ''}${gainLoss.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: gainLoss >= 0
                        ? GameThemeConstants.statPositive
                        : GameThemeConstants.statNegative,
                    fontWeight: FontWeight.w600,
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

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.value,
    this.showInfoTooltip = true,
  });

  final StatSchema stat;
  final num value;
  final bool showInfoTooltip;

  Color _getStatColor() {
    if (value > 0) return GameThemeConstants.statPositive;
    if (value < 0) return GameThemeConstants.statNegative;
    return GameThemeConstants.statNeutral;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatColor();
    final infoIcon = SizedBox(
      width: SpacingConstants.xl,
      height: SpacingConstants.xl,
      child: Center(
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
    final infoWidget = showInfoTooltip
        ? WidgetTooltip(
            message: Text(
              stat.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: GameThemeConstants.creamSurface,
              ),
            ),
            triggerMode: WidgetTooltipTriggerMode.tap,
            messageDecoration: BoxDecoration(
              color: GameThemeConstants.darkNavy,
              borderRadius: BorderRadius.circular(
                GameThemeConstants.radiusSmall,
              ),
              boxShadow: [
                BoxShadow(
                  color: GameThemeConstants.outlineColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            triangleColor: GameThemeConstants.darkNavy,
            messagePadding: const EdgeInsets.symmetric(
              horizontal: SpacingConstants.md,
              vertical: SpacingConstants.sm,
            ),
            child: infoIcon,
          )
        : infoIcon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingConstants.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(stat.displayName, style: TextStyle(color: color)),
          ),
          Text(
            value == value.roundToDouble()
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(width: SpacingConstants.xs),
          infoWidget,
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.maxWidth;
                    return Center(
                      child: Icon(
                        item.icon.toIconData(),
                        size: size * 0.6,
                        color: GameThemeConstants.primaryDark,
                      ),
                    );
                  },
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
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            item.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          switch (item) {
            StoreItemItem(:final statEffects) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: statEffects.entries
                  .where((e) => e.key != 'money')
                  .map(
                    (e) => Text(
                      '${_getStatDisplayName(e.key)}: ${e.value > 0 ? '+' : ''}${e.value.toStringAsFixed(e.value == e.value.roundToDouble() ? 0 : 1)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                children: [
                  Text(
                    'Return: ${expectedReturn.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Vol: ${volatility.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (managementCost > 0)
                    Text(
                      'Mgmt: ${managementCost.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
          },
          const Spacer(),
          GameButton(
            label: 'Buy',
            onPressed: canBuy ? onBuy : null,
            variant: GameButtonVariant.success,
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
