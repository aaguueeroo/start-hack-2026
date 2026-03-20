import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/portfolio_evolution_chart.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/engine/score_engine.dart';
import 'package:start_hack_2026/engine/win_condition_checker.dart';
import 'package:start_hack_2026/modules/leaderboard/controllers/leaderboard_controller.dart';

const List<String> _winnerImageAssetPaths = [
  'assets/images/winner/1.png',
  'assets/images/winner/2.png',
  'assets/images/winner/5.png',
  'assets/images/winner/6.png',
];

const List<String> _loserImageAssetPaths = [
  'assets/images/loser/1.png',
  'assets/images/loser/2.png',
  'assets/images/loser/3.png',
];

class GameWonScreen extends StatefulWidget {
  const GameWonScreen({super.key});

  @override
  State<GameWonScreen> createState() => _GameWonScreenState();
}

class _GameWonScreenState extends State<GameWonScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  late final AnimationController _stampController;
  late final Animation<double> _stampScale;
  late final Animation<double> _stampOpacity;
  late final Animation<double> _stampRotation;
  late final String _randomWinnerImagePath;
  late final String _randomLoserImagePath;
  String? _subtitleMessage;
  bool _showGrade = false;
  bool _victoryConfettiStarted = false;
  bool _stampRevealScheduled = false;

  static const Duration _confettiDuration = Duration(seconds: 3);
  static const Duration _routeTransitionDelay = Duration(milliseconds: 450);
  static const Duration _victoryStampDelay = Duration(milliseconds: 3100);
  static const Duration _stampAnimDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: _confettiDuration);
    _stampController = AnimationController(
      vsync: this,
      duration: _stampAnimDuration,
    );
    _stampScale = Tween<double>(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _stampRotation = Tween<double>(begin: -0.45, end: -0.26).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
    _randomWinnerImagePath =
        _winnerImageAssetPaths[math.Random().nextInt(
          _winnerImageAssetPaths.length,
        )];
    _randomLoserImagePath =
        _loserImageAssetPaths[math.Random().nextInt(
          _loserImageAssetPaths.length,
        )];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _stampController.dispose();
    super.dispose();
  }

  void _scheduleConfettiIfVictory(_EndgameKind kind) {
    if (kind != _EndgameKind.victory) return;
    if (_victoryConfettiStarted) return;
    _victoryConfettiStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _confettiController.play();
      });
    });
  }

  void _scheduleStampReveal(_EndgameKind kind) {
    if (_stampRevealScheduled) return;
    _stampRevealScheduled = true;
    if (kind == _EndgameKind.victory) {
      Future<void>.delayed(_victoryStampDelay, () {
        if (!mounted) return;
        setState(() => _showGrade = true);
        _stampController.forward();
      });
    } else {
      Future<void>.delayed(_routeTransitionDelay, () {
        if (!mounted) return;
        setState(() => _showGrade = true);
        _stampController.forward();
      });
    }
  }

  void _handleBackPressed() {
    final gameEngine = context.read<GameEngine>();
    final state = gameEngine.state;
    if (state == null) {
      context.go('/');
      return;
    }
    final scoreEngine = ScoreEngine();
    final scoreResult = scoreEngine.calculateScore(
      personaId: state.character.id,
      portfolioHistory: state.portfolioHistory,
      cumulativeDataPoints: state.cumulativeSimulationDataPoints,
      cumulativeEvents: state.cumulativeSimulationEvents,
      finalHoldings: state.holdings,
    );
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _SaveScoreDialog(
        score: scoreResult.totalScore,
        characterType: state.character.name,
        onSkip: () {
          Navigator.of(dialogContext).pop();
          context.go('/');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
          ),
        ),
        child: Consumer<GameEngine>(
          builder: (context, gameEngine, _) {
            final state = gameEngine.state;
            if (state == null) {
              return SafeArea(
                child: Center(
                  child: GameButton(
                    label: 'Back to Home',
                    onPressed: () => context.go('/'),
                    variant: GameButtonVariant.primary,
                  ),
                ),
              );
            }
            final character = state.character;
            final portfolioHistory = state.portfolioHistory;
            final finalValue = portfolioHistory.isNotEmpty
                ? portfolioHistory.last.value
                : 0.0;
            final startValue = portfolioHistory.isNotEmpty
                ? portfolioHistory.first.value
                : 0.0;
            final growthPercent = startValue > 0
                ? ((finalValue - startValue) / startValue * 100)
                : 0.0;
            final roundsPlayed = (portfolioHistory.length - 1).clamp(0, 999);
            final scoreEngine = ScoreEngine();
            final scoreResult = scoreEngine.calculateScore(
              personaId: character.id,
              portfolioHistory: portfolioHistory,
              cumulativeDataPoints: state.cumulativeSimulationDataPoints,
              cumulativeEvents: state.cumulativeSimulationEvents,
              finalHoldings: state.holdings,
            );
            final feedback = scoreEngine.buildFinalFeedback(
              personaId: character.id,
              personaLabel: character.name,
              score: scoreResult,
              roundsPlayed: roundsPlayed,
            );
            final won = WinConditionChecker.checkWin(
              character: character,
              portfolioHistory: portfolioHistory,
            );
            final bankrupt = finalValue <= 0;
            final endgameKind = bankrupt
                ? _EndgameKind.bankrupt
                : won
                ? _EndgameKind.victory
                : _EndgameKind.seasonComplete;
            _scheduleConfettiIfVictory(endgameKind);
            _scheduleStampReveal(endgameKind);
            _subtitleMessage ??= _EndgameHeader.pickSubtitle(endgameKind);
            return Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _EndgameHeader(
                          kind: endgameKind,
                          subtitleMessage: _subtitleMessage!,
                          characterName: character.name,
                          grade: feedback.grade,
                          showGrade: _showGrade,
                          stampScale: _stampScale,
                          stampOpacity: _stampOpacity,
                          stampRotation: _stampRotation,
                          winnerImageAssetPath: _randomWinnerImagePath,
                          loserImageAssetPath: _randomLoserImagePath,
                        ),
                        const SizedBox(height: 24),
                        _FinalFeedbackSection(feedback: feedback),
                        const SizedBox(height: 32),
                        _PortfolioEvolutionSection(
                          portfolioHistory: portfolioHistory,
                          finalValue: finalValue,
                          yearsPlayed: roundsPlayed,
                          growthPercent: growthPercent,
                        ),
                        const SizedBox(height: 24),
                        GameButton(
                          label: 'Continue',
                          icon: Icons.arrow_forward,
                          onPressed: _handleBackPressed,
                          variant: GameButtonVariant.success,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                if (endgameKind == _EndgameKind.victory)
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      emissionFrequency: 0.04,
                      numberOfParticles: 12,
                      maxBlastForce: 15,
                      minBlastForce: 5,
                      gravity: 0.15,
                      particleDrag: 0.05,
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFFFF6B6B),
                        Color(0xFF4ECDC4),
                        Color(0xFF7B6BFF),
                        Color(0xFFFF9A56),
                        Color(0xFF45B7D1),
                        Color(0xFFF7DC6F),
                      ],
                      createParticlePath: _drawStar,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Path _drawStar(Size size) {
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = (2 * math.pi) / numberOfPoints;
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < 2 * math.pi; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }
}

enum _EndgameKind { victory, bankrupt, seasonComplete }

class _EndgameHeader extends StatelessWidget {
  const _EndgameHeader({
    required this.kind,
    required this.subtitleMessage,
    required this.characterName,
    required this.grade,
    required this.showGrade,
    required this.stampScale,
    required this.stampOpacity,
    required this.stampRotation,
    required this.winnerImageAssetPath,
    required this.loserImageAssetPath,
  });

  final _EndgameKind kind;
  final String subtitleMessage;
  final String characterName;
  final String grade;
  final bool showGrade;
  final Animation<double> stampScale;
  final Animation<double> stampOpacity;
  final Animation<double> stampRotation;
  final String winnerImageAssetPath;
  final String loserImageAssetPath;

  static const Map<_EndgameKind, List<String>> _memeyTitles = {
    _EndgameKind.victory: [
      'Stonks Only Go Up!',
      'Warren Buffett Who?',
      'To The Moon!',
      'Money Printer Go Brr',
      'Galaxy Brain Investor',
    ],
    _EndgameKind.bankrupt: [
      'Oof. GG.',
      'Buy High, Sell Low Champion',
      'Diamond Hands... of Dust',
      'Not Stonks',
      'F in the Chat',
    ],
    _EndgameKind.seasonComplete: [
      'Time\'s Up, Champ!',
      'Run Complete, Legend',
      'Not Bad, Rookie!',
      'Season Finale',
      'GG, Well Played',
    ],
  };

  static const List<String> _winningSubtitles = [
    'Starting young paid off – great growth!',
    'Perfect balance – steady growth all the way!',
    'Steady and safe – your patience rewarded you!',
    'You embraced volatility and came out on top!',
    'You grew your inheritance wisely!',
    'To the moon and back!',
    'Diamond hands paid off!',
    'Your portfolio said yes to gains!',
    'The only way was up – and you nailed it!',
    'Compound interest who? You!',
  ];

  static const List<String> _losingSubtitles = [
    'At least you tried! (Kinda)',
    'Paper hands, meet the market.',
    'The market giveth, the market taketh…',
    'Not every hero wears a cape. Or wins.',
    'Portfolio said no to gains today.',
    'Time to read Investing for Dummies again.',
    'Even Warren Buffett had bad days. Probably.',
    'RIP portfolio. Gone but not forgotten.',
    'The market humbled you. It humbles us all.',
    'Buy high, sell low – the classic strategy.',
  ];

  static String pickSubtitle(_EndgameKind kind) {
    final list = kind == _EndgameKind.victory
        ? _winningSubtitles
        : _losingSubtitles;
    return list[math.Random().nextInt(list.length)];
  }

  String _getMemeyTitle() {
    final titles = _memeyTitles[kind] ?? ['GG!'];
    return titles[DateTime.now().millisecond % titles.length];
  }

  Color _getKindColor() {
    return switch (kind) {
      _EndgameKind.victory => GameThemeConstants.primaryDark,
      _EndgameKind.bankrupt => GameThemeConstants.dangerDark,
      _EndgameKind.seasonComplete => GameThemeConstants.primaryDark,
    };
  }

  Color _getMemeyTitleColor() {
    return switch (kind) {
      _EndgameKind.victory => GameThemeConstants.primaryDark,
      _EndgameKind.bankrupt => GameThemeConstants.dangerDark,
      _EndgameKind.seasonComplete => GameThemeConstants.dangerDark,
    };
  }

  IconData _getFallbackIcon() {
    return switch (kind) {
      _EndgameKind.victory => Icons.emoji_events,
      _EndgameKind.bankrupt => Icons.money_off,
      _EndgameKind.seasonComplete => Icons.flag,
    };
  }

  static Color _gradeColor(String grade) {
    return switch (grade) {
      'A' => const Color(0xFF22C55E),
      'B' => const Color(0xFF3B82F6),
      'C' => const Color(0xFFFACC15),
      'D' => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
  }

  /// Nudges the stamp down-right so it reads like a real ink stamp, not centered.
  static const Offset _gradeStampOffset = Offset(26, 18);

  @override
  Widget build(BuildContext context) {
    final kindColor = _getKindColor();
    return Column(
      children: [
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            if (kind == _EndgameKind.victory)
              Image.asset(
                winnerImageAssetPath,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(_getFallbackIcon(), size: 80, color: kindColor),
              )
            else
              Image.asset(
                loserImageAssetPath,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(_getFallbackIcon(), size: 80, color: kindColor),
              ),
            if (showGrade)
              AnimatedBuilder(
                animation: stampScale,
                builder: (context, child) {
                  return Transform.translate(
                    offset: _gradeStampOffset,
                    child: Transform.rotate(
                      angle: stampRotation.value,
                      child: Transform.scale(
                        scale: stampScale.value,
                        child: Opacity(
                          opacity: stampOpacity.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: _GradeStamp(grade: grade, color: _gradeColor(grade)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _getMemeyTitle(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: _getMemeyTitleColor(),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitleMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: GameThemeConstants.outlineColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '— $characterName',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: GameThemeConstants.outlineColorLight,
          ),
        ),
      ],
    );
  }
}

class _GradeStamp extends StatelessWidget {
  const _GradeStamp({required this.grade, required this.color});

  final String grade;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 5),
        color: color.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 5),
          child: Text(
            grade,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: GoogleFonts.specialElite(
              fontSize: 52,
              height: 1.0,
              letterSpacing: 1,
              color: color,
              shadows: [
                Shadow(
                  offset: const Offset(1.5, 2.5),
                  blurRadius: 0,
                  color: color.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioEvolutionSection extends StatelessWidget {
  const _PortfolioEvolutionSection({
    required this.portfolioHistory,
    required this.finalValue,
    required this.yearsPlayed,
    required this.growthPercent,
  });

  final List<PortfolioHistoryPoint> portfolioHistory;
  final double finalValue;
  final int yearsPlayed;
  final double growthPercent;

  @override
  Widget build(BuildContext context) {
    final TextStyle? headerStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Portfolio Evolution', style: headerStyle),
        ),
        const SizedBox(height: 8),
        GameCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PortfolioEvolutionChart(dataPoints: portfolioHistory),
                const SizedBox(height: 16),
                _FinalStatsRow(
                  finalValue: finalValue,
                  yearsPlayed: yearsPlayed,
                  growthPercent: growthPercent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FinalStatsRow extends StatelessWidget {
  const _FinalStatsRow({
    required this.finalValue,
    required this.yearsPlayed,
    required this.growthPercent,
  });

  final double finalValue;
  final int yearsPlayed;
  final double growthPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Final Value',
            value: '\$${finalValue.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Years',
            value: '$yearsPlayed',
            icon: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            label: 'Growth',
            value:
                '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            isPositive: growthPercent >= 0,
          ),
        ),
      ],
    );
  }
}

class _FinalFeedbackSection extends StatefulWidget {
  const _FinalFeedbackSection({required this.feedback});

  final FinalScoreFeedback feedback;

  @override
  State<_FinalFeedbackSection> createState() => _FinalFeedbackSectionState();
}

class _FinalFeedbackSectionState extends State<_FinalFeedbackSection> {
  OverlayEntry? _reportOverlayEntry;
  GlobalKey? _openTileKey;
  late final List<GlobalKey> _tileKeys;

  static const List<(String, String, IconData)> _dimensions = [
    ('wealth', 'Wealth', Icons.account_balance),
    ('drawdown', 'Drawdown', Icons.trending_down),
    ('behavior', 'Behavior', Icons.psychology),
    ('diversification', 'Diversification', Icons.pie_chart),
    ('real_return', 'Real Return', Icons.show_chart),
    ('fidelity', 'Fidelity', Icons.verified_user),
  ];

  @override
  void initState() {
    super.initState();
    _tileKeys = List<GlobalKey>.generate(
      _dimensions.length,
      (int i) => GlobalKey(debugLabel: 'report_card_tile_$i'),
    );
  }

  @override
  void dispose() {
    _hideReportOverlay();
    super.dispose();
  }

  void _hideReportOverlay() {
    _reportOverlayEntry?.remove();
    _reportOverlayEntry = null;
    _openTileKey = null;
  }

  GlobalKey? _findTileKeyAt(Offset globalPosition) {
    for (var i = 0; i < _dimensions.length; i++) {
      final (String, String, IconData) dim = _dimensions[i];
      final dimension = widget.feedback.dimensions[dim.$1];
      if (dimension == null) {
        continue;
      }
      final RenderBox? box =
          _tileKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        continue;
      }
      final Rect rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.contains(globalPosition)) {
        return _tileKeys[i];
      }
    }
    return null;
  }

  void _handleReportBarrierPointerUp(Offset globalPosition) {
    final GlobalKey? hitKey = _findTileKeyAt(globalPosition);
    if (hitKey != null && identical(hitKey, _openTileKey)) {
      _hideReportOverlay();
      return;
    }
    if (hitKey != null) {
      for (var i = 0; i < _dimensions.length; i++) {
        if (!identical(_tileKeys[i], hitKey)) {
          continue;
        }
        final (String, String, IconData) dim = _dimensions[i];
        final dimension = widget.feedback.dimensions[dim.$1];
        if (dimension == null) {
          _hideReportOverlay();
          return;
        }
        _hideReportOverlay();
        _showReportOverlay(
          tileKey: hitKey,
          label: dim.$2,
          icon: dim.$3,
          explanation: dimension.explanation,
          tip: dimension.tip,
        );
        return;
      }
    }
    _hideReportOverlay();
  }

  void _showReportOverlay({
    required GlobalKey tileKey,
    required String label,
    required IconData icon,
    required String explanation,
    required String tip,
  }) {
    if (_reportOverlayEntry != null && identical(_openTileKey, tileKey)) {
      _hideReportOverlay();
      return;
    }
    _hideReportOverlay();
    _openTileKey = tileKey;
    _reportOverlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) => Positioned.fill(
        child: _ReportCardTooltipOverlay(
          tileKey: tileKey,
          label: label,
          icon: icon,
          explanation: explanation,
          tip: tip,
          onBarrierPointerUp: _handleReportBarrierPointerUp,
        ),
      ),
    );
    Overlay.of(context).insert(_reportOverlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Your Report Card',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.feedback.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GameThemeConstants.outlineColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFeedbackGrid(context),
      ],
    );
  }

  Widget _buildFeedbackGrid(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < _dimensions.length; i++) {
      final (String, String, IconData) dim = _dimensions[i];
      final dimension = widget.feedback.dimensions[dim.$1];
      if (dimension == null) continue;
      items.add(
        _FeedbackMedalTile(
          key: _tileKeys[i],
          label: dim.$2,
          icon: dim.$3,
          score: dimension.score,
          max: dimension.max,
          onTap: () => _showReportOverlay(
            tileKey: _tileKeys[i],
            label: dim.$2,
            icon: dim.$3,
            explanation: dimension.explanation,
            tip: dimension.tip,
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: items,
    );
  }
}

class _ReportCardTooltipOverlay extends StatefulWidget {
  const _ReportCardTooltipOverlay({
    required this.tileKey,
    required this.label,
    required this.icon,
    required this.explanation,
    required this.tip,
    required this.onBarrierPointerUp,
  });

  final GlobalKey tileKey;
  final String label;
  final IconData icon;
  final String explanation;
  final String tip;
  final ValueChanged<Offset> onBarrierPointerUp;

  @override
  State<_ReportCardTooltipOverlay> createState() =>
      _ReportCardTooltipOverlayState();
}

class _ReportCardTooltipOverlayState extends State<_ReportCardTooltipOverlay> {
  Offset? _tilePosition;
  Size? _tileSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  void _updatePosition() {
    final RenderBox? renderBox =
        widget.tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && mounted) {
      setState(() {
        _tilePosition = renderBox.localToGlobal(Offset.zero);
        _tileSize = renderBox.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            onPointerUp: (PointerUpEvent e) =>
                widget.onBarrierPointerUp(e.position),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        if (_tilePosition != null && _tileSize != null)
          _ReportCardTooltipPopup(
            tilePosition: _tilePosition!,
            tileSize: _tileSize!,
            label: widget.label,
            icon: widget.icon,
            explanation: widget.explanation,
            tip: widget.tip,
          ),
      ],
    );
  }
}

class _ReportCardTooltipPopup extends StatelessWidget {
  const _ReportCardTooltipPopup({
    required this.tilePosition,
    required this.tileSize,
    required this.label,
    required this.icon,
    required this.explanation,
    required this.tip,
  });

  final Offset tilePosition;
  final Size tileSize;
  final String label;
  final IconData icon;
  final String explanation;
  final String tip;

  static const double _tooltipMaxWidth = 280.0;
  static const double _arrowHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    const double spacing = SpacingConstants.sm;
    final double horizontalPadding = SpacingConstants.md;
    final double tooltipWidth = math.min(
      _tooltipMaxWidth,
      screenWidth - horizontalPadding * 2,
    );
    final double cardCenterX = tilePosition.dx + tileSize.width / 2;
    double tooltipLeft = cardCenterX - tooltipWidth / 2;
    tooltipLeft = tooltipLeft.clamp(
      horizontalPadding,
      screenWidth - tooltipWidth - horizontalPadding,
    );
    final double arrowCenterX = cardCenterX - tooltipLeft;
    final bool showAbove = tilePosition.dy > screenHeight / 2;
    final double maxPopupHeight = screenHeight * 0.45;
    return Positioned(
      left: tooltipLeft,
      top: showAbove ? null : tilePosition.dy + tileSize.height + spacing,
      bottom: showAbove ? screenHeight - tilePosition.dy + spacing : null,
      width: tooltipWidth,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showAbove) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxPopupHeight),
                child: SingleChildScrollView(
                  child: _ReportCardTooltipBody(
                    label: label,
                    icon: icon,
                    explanation: explanation,
                    tip: tip,
                  ),
                ),
              ),
              CustomPaint(
                size: Size(tooltipWidth, _arrowHeight),
                painter: _ReportCardTooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowCenterX,
                  pointingDown: true,
                ),
              ),
            ] else ...[
              CustomPaint(
                size: Size(tooltipWidth, _arrowHeight),
                painter: _ReportCardTooltipArrowPainter(
                  color: GameThemeConstants.creamSurface,
                  borderColor: GameThemeConstants.outlineColor,
                  arrowCenterX: arrowCenterX,
                  pointingDown: false,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxPopupHeight),
                child: SingleChildScrollView(
                  child: _ReportCardTooltipBody(
                    label: label,
                    icon: icon,
                    explanation: explanation,
                    tip: tip,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportCardTooltipArrowPainter extends CustomPainter {
  const _ReportCardTooltipArrowPainter({
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
    const double arrowWidth = 16.0;
    final Path path = Path();
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

class _ReportCardTooltipBody extends StatelessWidget {
  const _ReportCardTooltipBody({
    required this.label,
    required this.icon,
    required this.explanation,
    required this.tip,
  });

  final String label;
  final IconData icon;
  final String explanation;
  final String tip;

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(icon, size: 20, color: GameThemeConstants.primaryDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GameThemeConstants.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingConstants.sm),
          Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: SpacingConstants.sm),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GameThemeConstants.accentDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                SpacingConstants.gameRadiusSm,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: GameThemeConstants.accentDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GameThemeConstants.accentDark,
                      fontWeight: FontWeight.w600,
                    ),
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

class _FeedbackMedalTile extends StatelessWidget {
  const _FeedbackMedalTile({
    super.key,
    required this.label,
    required this.icon,
    required this.score,
    required this.max,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int score;
  final int max;
  final VoidCallback onTap;

  String _computeDimensionGrade() {
    if (max <= 0) return 'F';
    final ratio = score / max;
    if (ratio >= 0.85) return 'A';
    if (ratio >= 0.70) return 'B';
    if (ratio >= 0.55) return 'C';
    if (ratio >= 0.40) return 'D';
    return 'F';
  }

  static Color _gradeColor(String grade) {
    return switch (grade) {
      'A' => const Color(0xFF22C55E),
      'B' => const Color(0xFF3B82F6),
      'C' => const Color(0xFFFACC15),
      'D' => const Color(0xFFF97316),
      _ => const Color(0xFFEF4444),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensionGrade = _computeDimensionGrade();
    final color = _gradeColor(dimensionGrade);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: GameThemeConstants.creamSurface,
          borderRadius: BorderRadius.circular(SpacingConstants.gameRadiusSm),
          border: Border.all(
            color: GameThemeConstants.outlineColor,
            width: GameThemeConstants.outlineThicknessSmall,
          ),
          boxShadow: [
            BoxShadow(
              color: GameThemeConstants.outlineColor.withValues(alpha: 0.1),
              offset: const Offset(0, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: GameThemeConstants.outlineColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            _MedalWithGrade(grade: dimensionGrade, color: color),
            const SizedBox(height: 4),
            Text(
              '$score/$max',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: GameThemeConstants.outlineColorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedalWithGrade extends StatelessWidget {
  const _MedalWithGrade({required this.grade, required this.color});

  final String grade;
  final Color color;

  static const String _medalAssetPath = 'assets/images/medal.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            _medalAssetPath,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.military_tech, size: 56, color: color),
          ),
          Positioned(
            top: 14,
            child: Transform.translate(
              offset: const Offset(0, 3),
              child: Text(
                grade,
                textHeightBehavior: const TextHeightBehavior(
                  applyHeightToFirstAscent: false,
                  applyHeightToLastDescent: false,
                ),
                style: GoogleFonts.specialElite(
                  fontSize: 30,
                  height: 1.0,
                  letterSpacing: 0.5,
                  color: color,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 4,
                    ),
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.9),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({
    required this.score,
    required this.characterType,
    required this.onSkip,
  });

  final int score;
  final String characterType;
  final VoidCallback onSkip;

  @override
  State<_SaveScoreDialog> createState() => _SaveScoreDialogState();
}

class _SaveScoreDialogState extends State<_SaveScoreDialog> {
  late final TextEditingController _nameController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _prefillSavedName();
  }

  Future<void> _prefillSavedName() async {
    final savedName = await context
        .read<LeaderboardController>()
        .getSavedPlayerName();
    if (!mounted) return;
    if (savedName != null && savedName.trim().isNotEmpty) {
      _nameController.text = savedName.trim();
    }
  }

  Future<void> _saveAndGoToLeaderboard() async {
    final playerName = _nameController.text.trim();
    if (playerName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final leaderboardController = context.read<LeaderboardController>();
      await leaderboardController.saveScore(
        playerName: playerName,
        characterType: widget.characterType,
        score: widget.score,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      context.pushReplacement('/leaderboard');
    } catch (e) {
      print('Failed to save score: $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Save failed. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GameThemeConstants.creamSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GameThemeConstants.radiusMedium),
        side: BorderSide(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThickness,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard,
              size: 48,
              color: GameThemeConstants.primaryDark,
            ),
            const SizedBox(height: 12),
            Text(
              'Save Your Score?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: GameThemeConstants.outlineColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${widget.score}/100',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: GameThemeConstants.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveAndGoToLeaderboard(),
              decoration: const InputDecoration(
                labelText: 'Player name',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: GameThemeConstants.dangerDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            GameButton(
              label: _isSaving ? 'Saving...' : 'Save & View Leaderboard',
              icon: _isSaving ? null : Icons.save,
              onPressed: _isSaving ? null : _saveAndGoToLeaderboard,
              variant: GameButtonVariant.primary,
            ),
            const SizedBox(height: 10),
            GameButton(
              label: 'Skip & Go Home',
              icon: Icons.home,
              onPressed: widget.onSkip,
              variant: GameButtonVariant.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.isPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool? isPositive;

  @override
  Widget build(BuildContext context) {
    final valueColor = isPositive == null
        ? GameThemeConstants.primaryDark
        : isPositive!
        ? GameThemeConstants.statPositive
        : GameThemeConstants.statNegative;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: GameThemeConstants.creamSurface,
        borderRadius: BorderRadius.circular(SpacingConstants.gameRadiusSm),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThicknessSmall,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: GameThemeConstants.primaryDark),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: GameThemeConstants.outlineColorLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
