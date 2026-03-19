import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/core/widgets/game_resource_counter.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/domain/entities/store_item.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().loadStoreData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameThemeConstants.creamBackground,
              Color(0xFFF5EDE0),
            ],
          ),
        ),
        child: Consumer<StoreController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: GameProgressIndicator());
          }
          if (controller.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingConstants.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: SpacingConstants.md),
                    GameButton(
                      label: 'Retry',
                      onPressed: () => controller.loadStoreData(),
                      variant: GameButtonVariant.primary,
                    ),
                  ],
                ),
              ),
            );
          }
          if (controller.character == null) {
            return Center(
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
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingConstants.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoneyDisplay(cash: controller.cash),
                const SizedBox(height: SpacingConstants.lg),
                _StatsSection(
                  stats: controller.stats,
                  schema: controller.statsSchema,
                ),
                const SizedBox(height: SpacingConstants.lg),
                Text(
                  'Buy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: SpacingConstants.sm),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: SpacingConstants.md,
                    mainAxisSpacing: SpacingConstants.md,
                  ),
                  itemCount: controller.storeOffer.length,
                  itemBuilder: (context, index) {
                    return _StoreItemCard(
                      item: controller.storeOffer[index],
                      canBuy: controller.canBuy(controller.storeOffer[index]),
                      onBuy: () => controller.purchase(controller.storeOffer[index]),
                    );
                  },
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
          );
        },
      ),
    ),
    );
  }
}

class _MoneyDisplay extends StatelessWidget {
  const _MoneyDisplay({required this.cash});

  final int cash;

  @override
  Widget build(BuildContext context) {
    return GameResourceCounter(
      label: 'Money',
      value: '\$$cash',
      icon: Icons.monetization_on,
      iconColor: GameThemeConstants.warningLight,
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.stats,
    required this.schema,
  });

  final Map<String, num> stats;
  final List<StatSchema> schema;

  @override
  Widget build(BuildContext context) {
    final displayStats = schema
        .where((s) => stats.containsKey(s.id) && s.id != 'money')
        .toList();
    if (displayStats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: SpacingConstants.sm),
        ...displayStats.map((stat) => _StatRow(stat: stat, value: stats[stat.id] ?? 0)),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, required this.value});

  final StatSchema stat;
  final num value;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.md,
        vertical: SpacingConstants.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(stat.displayName),
          ),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(stat.displayName),
                  content: Text(stat.description),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
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
  });

  final StoreItem item;
  final bool canBuy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.icon.toIconData(),
              size: 32,
              color: GameThemeConstants.primaryDark,
            ),
            const SizedBox(height: SpacingConstants.sm),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            switch (item) {
              StoreItemItem(:final statEffects) => Text(
                  _formatEffects(statEffects),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              StoreItemAsset(:final expectedReturn) => Text(
                  'Return: $expectedReturn%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            },
            const SizedBox(height: SpacingConstants.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${item.price}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                GameButton(
                  label: 'Buy',
                  onPressed: canBuy ? onBuy : null,
                  variant: GameButtonVariant.success,
                  isFullWidth: false,
                ),
              ],
            ),
          ],
        ),
    );
  }

  String _formatEffects(Map<String, int> effects) {
    return effects.entries
        .map((e) => '${e.key}: ${e.value > 0 ? '+' : ''}${e.value}')
        .join(', ');
  }
}
