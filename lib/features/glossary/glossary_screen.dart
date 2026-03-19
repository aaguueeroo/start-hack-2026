import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/data/loaders/json_data_loader.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/domain/entities/stat_schema.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  List<StatSchema> _stats = [];
  List<Character> _characters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final loader = context.read<JsonDataLoader>();
    final gameController = context.read<GameController>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final statsFuture = loader.loadStatsSchema();
      final charsFuture = gameController.loadCharacters();
      final stats = await statsFuture;
      await charsFuture;
      setState(() {
        _stats = stats;
        _characters = gameController.characters;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('GlossaryScreen: Failed to load data: $e');
      setState(() {
        _stats = [];
        _characters = [];
        _isLoading = false;
        _errorMessage = 'Could not load glossary. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Glossary'),
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
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
          ),
        ),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: GameProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(SpacingConstants.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: SpacingConstants.md),
              GameButton(
                label: 'Retry',
                onPressed: _loadData,
                variant: GameButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              SpacingConstants.md,
              SpacingConstants.sm,
              SpacingConstants.md,
              SpacingConstants.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(title: 'Investing Best Practices'),
                const SizedBox(height: SpacingConstants.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConstants.md,
                  ),
                  child: const _BestPracticesSection(),
                ),
                const SizedBox(height: SpacingConstants.xxl),
                _SectionHeader(title: 'Character Archetypes'),
                const SizedBox(height: SpacingConstants.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConstants.md,
                  ),
                  child: _CharacterSkillsSection(characters: _characters),
                ),
                const SizedBox(height: SpacingConstants.xxl),
                _SectionHeader(title: 'Stats & Skills'),
                const SizedBox(height: SpacingConstants.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConstants.md,
                  ),
                  child: _StatsSection(stats: _stats),
                ),
                const SizedBox(height: SpacingConstants.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.md,
        vertical: SpacingConstants.sm,
      ),
      backgroundColor: GameThemeConstants.primaryDark.withValues(alpha: 0.5),
      child: Text(
        title,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final List<StatSchema> stats;

  static const Map<String, String> _extraStats = {
    'riskTolerance': 'Risk Tolerance',
    'financialKnowledge': 'Financial Knowledge',
  };

  static const Map<String, String> _extendedDescriptions = {
    'money':
        'Your available cash—the amount you can spend on knowledge items and financial assets. Money does not earn returns on its own; it must be invested. Keeping too much in cash means missing out on growth, but you need some on hand for opportunities and emergencies.',
    'assetSlots':
        'The maximum number of different assets you can hold at once. Each slot lets you own one type of investment (e.g. bonds, stocks, funds). More slots allow better diversification, spreading risk across different markets and asset classes.',
    'knowledgeSlots':
        'How many knowledge items you can own at the same time. Empty slots can be filled from the store. You can buy the same card again to merge it with an existing copy (same level) into a higher level, or place it in a free slot if you have one.',
    'monthlySavings':
        'The amount you save and invest each month. This is added to your portfolio at the end of every month during the simulation. Higher savings accelerate growth through compound returns. Consistency matters more than timing the market.',
    'return':
        'The expected annual return of your portfolio, expressed as a percentage. It reflects the weighted average of your holdings. Higher-return assets usually come with higher volatility. Past returns do not guarantee future results.',
    'volatility':
        'A measure of how much your portfolio value fluctuates over time. High volatility means bigger swings—both up and down. Volatile assets can deliver strong returns but may force selling during downturns if your risk tolerance is low.',
    'diversification':
        'How spread out your investments are across different assets. Good diversification reduces risk because when one asset falls, others may hold or rise. Avoid putting all your money in a single investment or sector.',
    'sharpeRatio':
        'A risk-adjusted return measure: how much extra return you get per unit of risk. A higher Sharpe ratio means better reward for the volatility you accept. It helps compare portfolios that have different risk levels.',
    'managementCostDrag':
        'The total cost of managing your investments, expressed as a percentage of your portfolio per year. Fees eat into returns over time. Even small percentages compound—a 1% fee can cost tens of thousands over decades.',
    'liquidityRatio':
        'How easily you can access your funds without losing value. Cash and bonds are highly liquid; real estate and some funds are less so. You may need to sell at a bad time if liquidity is low when you need money.',
    'taxDrag':
        'The impact of taxes on your investment returns. Dividends, capital gains, and interest are often taxed. Tax-efficient strategies and accounts can reduce this drag and leave more money growing for you.',
    'emotionalReaction':
        'How you respond to market swings. A high score means you stay calm during downturns; a low score means you may panic and sell at the worst time. Emotional selling locks in losses and misses recoveries.',
    'knowledge':
        'Your level of financial literacy. It affects how well you evaluate investments, avoid scams, and make informed decisions. You can improve it by buying knowledge items in the store.',
    'investmentHorizonRemaining':
        'The number of years until you expect to need the money. A longer horizon lets you take more risk and ride out downturns. As the horizon shortens, shifting toward safer assets helps protect what you\'ve built.',
    'savingsRate':
        'The percentage of your income that you save and invest. A higher rate builds wealth faster. Even small increases—from 10% to 15%—can make a big difference over decades through compounding.',
    'behavioralBias':
        'Your tendency to make emotional or impulsive decisions. High bias leads to chasing returns, panic-selling, or avoiding good opportunities. Lower bias means more disciplined, rational investing.',
    'riskTolerance':
        'How much market volatility you can stomach without panicking. Higher values mean you\'re less likely to be forced to sell during downturns. It depends on your personality, goals, and time horizon. Know your limits before investing.',
    'financialKnowledge':
        'Your understanding of investments and financial concepts. It affects how well you evaluate opportunities, avoid costly mistakes, and choose suitable assets. You can boost it by purchasing knowledge items in the store.',
  };

  @override
  Widget build(BuildContext context) {
    final existingIds = stats.map((s) => s.id).toSet();
    final allStats = [
      ...stats,
      for (final id in _extraStats.keys)
        if (!existingIds.contains(id))
          StatSchema(
            id: id,
            displayName: _extraStats[id]!,
            description: _extendedDescriptions[id]!,
          ),
    ];
    final byCategory = <String, List<StatSchema>>{};
    for (final stat in allStats) {
      final category = stat.category ?? 'general';
      byCategory.putIfAbsent(category, () => []).add(stat);
    }
    final categoryOrder = ['general', 'personal', 'portfolio'];
    final orderedCategories = categoryOrder
        .where((c) => byCategory.containsKey(c))
        .toList();
    for (final key in byCategory.keys) {
      if (!categoryOrder.contains(key)) orderedCategories.add(key);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: orderedCategories
          .map(
            (category) => _StatCategoryBlock(
              categoryName: _formatCategoryName(category),
              stats: byCategory[category]!,
              extendedDescriptions: _extendedDescriptions,
            ),
          )
          .toList(),
    );
  }

  String _formatCategoryName(String category) {
    return switch (category) {
      'general' => 'General',
      'personal' => 'Personal',
      'portfolio' => 'Portfolio',
      _ => category[0].toUpperCase() + category.substring(1),
    };
  }
}

class _StatCategoryBlock extends StatelessWidget {
  const _StatCategoryBlock({
    required this.categoryName,
    required this.stats,
    required this.extendedDescriptions,
  });

  final String categoryName;
  final List<StatSchema> stats;
  final Map<String, String> extendedDescriptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: SpacingConstants.lg,
            bottom: SpacingConstants.md,
          ),
          child: Text(
            categoryName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: GameThemeConstants.primaryDark,
            ),
          ),
        ),
        ...stats.map(
          (stat) => _StatEntry(
            stat: stat,
            description: extendedDescriptions[stat.id] ?? stat.description,
          ),
        ),
        const SizedBox(height: SpacingConstants.md),
      ],
    );
  }
}

class _StatEntry extends StatelessWidget {
  const _StatEntry({required this.stat, required this.description});

  final StatSchema stat;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingConstants.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: GameThemeConstants.outlineColor,
            ),
          ),
          const SizedBox(height: SpacingConstants.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: GameThemeConstants.outlineColorLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterSkillsSection extends StatelessWidget {
  const _CharacterSkillsSection({required this.characters});

  final List<Character> characters;

  static const Map<String, String> _characterDescriptions = {
    'young_investor':
        'Starting young is one of the biggest advantages in investing. With a long time horizon, you can benefit from compound growth—earnings on your earnings—over decades. You can afford to take more risk because you have time to recover from downturns. The key is to start early and stay invested.',
    'middle_aged':
        'At this stage, you often balance growth with stability. You may have multiple goals: retirement, children\'s education, a house. A balanced approach—mixing stocks and bonds—helps you grow wealth while protecting what you\'ve built. Steady, consistent investing tends to work better than chasing hot trends.',
    'pre_retirement':
        'As you approach retirement, capital preservation becomes more important. You have less time to recover from market crashes, so reducing volatility and protecting your nest egg matters. Shifting toward safer assets like bonds and cash helps ensure the money is there when you need it.',
    'entrepreneur':
        'Entrepreneurs often have irregular income and high risk tolerance. You\'re used to volatility in business, so market swings may not faze you. The challenge is balancing lumpy cash flows with consistent investing. When income arrives, putting it to work in diversified assets can build long-term wealth.',
    'inheritor':
        'A large lump sum with no ongoing income pressure changes the game. You have capital to deploy but may lack experience. The temptation is to spend or make impulsive decisions. Taking time to learn, diversify, and invest for the long term can turn an inheritance into lasting wealth.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: characters
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingConstants.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GameThemeConstants.primaryDark,
                    ),
                  ),
                  const SizedBox(height: SpacingConstants.sm),
                  Text(
                    _characterDescriptions[c.id] ?? c.uniqueSkill,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _BestPracticesSection extends StatelessWidget {
  const _BestPracticesSection();

  static const List<_PracticeItem> _practices = [
    _PracticeItem(
      title: 'Start early',
      description:
          'Time in the market beats timing the market. Compound interest—earning returns on your returns—works best when you give it decades to grow. Even small amounts invested early can grow into substantial wealth. Waiting a few years can cost you hundreds of thousands in lost growth.',
    ),
    _PracticeItem(
      title: 'Diversify',
      description:
          'Don\'t put all your eggs in one basket. Spread investments across different assets, sectors, and regions. When one investment falls, others may hold or rise, smoothing out your overall returns. Diversification reduces risk without necessarily sacrificing long-term returns.',
    ),
    _PracticeItem(
      title: 'Invest regularly',
      description:
          'Monthly savings add up. Consistent investing smooths out market volatility through dollar-cost averaging: you buy more shares when prices are low and fewer when they\'re high. This discipline removes the need to guess the right moment to invest.',
    ),
    _PracticeItem(
      title: 'Know your risk tolerance',
      description:
          'Only take risks you can sleep with. If market swings keep you up at night, lean toward safer assets like bonds. If you can stomach volatility, stocks may offer higher long-term returns. Be honest with yourself—panic-selling during a crash locks in losses.',
    ),
    _PracticeItem(
      title: 'Keep costs low',
      description:
          'Management fees and taxes eat into returns. A 1% annual fee can cost you tens of thousands over decades. Choose low-cost index funds and tax-efficient strategies. Every dollar saved on fees stays invested and compounds for you.',
    ),
    _PracticeItem(
      title: 'Stay the course',
      description:
          'Avoid panic-selling in downturns. Markets have always recovered over time, but emotional decisions—selling when everyone is fearful—lock in losses and miss the recovery. Have a plan, stick to it, and tune out the noise.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _practices
          .map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingConstants.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GameThemeConstants.primaryDark,
                    ),
                  ),
                  const SizedBox(height: SpacingConstants.sm),
                  Text(
                    p.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: GameThemeConstants.outlineColorLight,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PracticeItem {
  const _PracticeItem({required this.title, required this.description});

  final String title;
  final String description;
}
