import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/character_image_constants.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/extensions/icon_extension.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/core/widgets/game_progress_indicator.dart';
import 'package:start_hack_2026/domain/entities/character.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';

Widget _buildCharacterAvatar(Character character) {
  final imagePath = CharacterImageConstants.getImagePathForCharacter(
    character.id,
  );
  if (imagePath != null) {
    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );
  }
  return Icon(
    character.icon.toIconData(),
    color: GameThemeConstants.primaryDark,
  );
}

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key, this.fromMultiplayer = false});

  final bool fromMultiplayer;

  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  Character? _selectedCharacter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameController>().loadCharacters();
    });
  }

  void _onConfirmSelection() {
    final character = _selectedCharacter;
    if (character == null) return;
    context.read<GameController>().startNewGame(character);
    if (widget.fromMultiplayer) {
      context.pop();
      return;
    }
    context.pushReplacement('/store');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Character'),
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
              Color.fromARGB(255, 232, 199, 141),
            ],
          ),
        ),
        child: Consumer<GameController>(
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
                      Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: SpacingConstants.md),
                      GameButton(
                        label: 'Retry',
                        onPressed: () => controller.loadCharacters(),
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
                        _SelectedCharacterSlot(
                          selectedCharacter: _selectedCharacter,
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        Text(
                          'Select a character',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: GameThemeConstants.primaryDark,
                              ),
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.5,
                                crossAxisSpacing: SpacingConstants.sm,
                                mainAxisSpacing: SpacingConstants.sm,
                              ),
                          itemCount: controller.characters.length,
                          itemBuilder: (context, index) {
                            final character = controller.characters[index];
                            final isSelected =
                                _selectedCharacter?.id == character.id;
                            return _CharacterListItem(
                              character: character,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedCharacter = character;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingConstants.md),
                    child: GameButton(
                      label: 'Confirm Choice',
                      onPressed: _selectedCharacter != null
                          ? _onConfirmSelection
                          : null,
                      variant: GameButtonVariant.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Core stats for the preview: readable at a glance, scales work for RPG bars.
const List<String> _previewStatIds = [
  'money',
  'riskTolerance',
  'financialKnowledge',
  'investmentHorizonRemaining',
];

class _SelectedCharacterSlot extends StatelessWidget {
  const _SelectedCharacterSlot({required this.selectedCharacter});

  final Character? selectedCharacter;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConstants.md,
        vertical: SpacingConstants.sm,
      ),
      child: SizedBox(
        height: SpacingConstants.selectedCharacterSlotHeight,
        child: selectedCharacter == null
            ? _buildPlaceholder(context)
            : _buildSelectedContent(context),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        '?',
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          color: GameThemeConstants.outlineColorLight,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildSelectedContent(BuildContext context) {
    final character = selectedCharacter!;
    const avatarWidth = 118.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: avatarWidth,
          child: Column(
            children: [
              Expanded(
                child: Center(child: _buildCharacterAvatar(character)),
              ),
              Text(
                character.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: GameThemeConstants.primaryDark,
                  height: 1.05,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: SpacingConstants.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final id in _previewStatIds) ...[
                _ComicStatBar(
                  label: _previewStatLabel(id),
                  value: (character.initialStats[id] ?? 0).toDouble(),
                  maxForBar: _previewStatMax(id),
                  valueCaption: _previewStatCaption(id, character.initialStats),
                  fillLight: _previewStatFillLight(id),
                  fillDark: _previewStatFillDark(id),
                ),
                const SizedBox(height: SpacingConstants.xs),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingConstants.sm,
                  vertical: SpacingConstants.xs,
                ),
                decoration: BoxDecoration(
                  color: GameThemeConstants.accentLight.withValues(
                    alpha: 0.28,
                  ),
                  borderRadius: BorderRadius.circular(
                    SpacingConstants.gameRadiusSm,
                  ),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _previewStatLabel(String id) {
    return switch (id) {
      'money' => 'CAPITAL',
      'riskTolerance' => 'RISK',
      'financialKnowledge' => 'FINANCE',
      'investmentHorizonRemaining' => 'RUNWAY',
      _ => id.toUpperCase(),
    };
  }

  static double _previewStatMax(String id) {
    return switch (id) {
      'money' => 80000,
      'riskTolerance' => 100,
      'financialKnowledge' => 100,
      'investmentHorizonRemaining' => 45,
      _ => 100,
    };
  }

  static String _previewStatCaption(String id, Map<String, num> stats) {
    final v = stats[id] ?? 0;
    return switch (id) {
      'money' => '\$${_formatMoney(v)}',
      'investmentHorizonRemaining' => '${v.toStringAsFixed(0)} yrs',
      _ => v.toStringAsFixed(0),
    };
  }

  static String _formatMoney(num value) {
    final n = value.round();
    if (n >= 1000) {
      return '${(n / 1000).round()}k';
    }
    return n.toString();
  }

  static Color _previewStatFillLight(String id) {
    return switch (id) {
      'money' => GameThemeConstants.warningLight,
      'riskTolerance' => GameThemeConstants.orangeLight,
      'financialKnowledge' => GameThemeConstants.primaryLight,
      'investmentHorizonRemaining' => GameThemeConstants.skyBlueLight,
      _ => GameThemeConstants.accentLight,
    };
  }

  static Color _previewStatFillDark(String id) {
    return switch (id) {
      'money' => GameThemeConstants.warningDark,
      'riskTolerance' => GameThemeConstants.orangeDark,
      'financialKnowledge' => GameThemeConstants.primaryDark,
      'investmentHorizonRemaining' => GameThemeConstants.skyBlueDark,
      _ => GameThemeConstants.accentDark,
    };
  }
}

/// Chunky outlined fill bar (comic / RPG character sheet).
class _ComicStatBar extends StatelessWidget {
  const _ComicStatBar({
    required this.label,
    required this.value,
    required this.maxForBar,
    required this.valueCaption,
    required this.fillLight,
    required this.fillDark,
  });

  final String label;
  final double value;
  final double maxForBar;
  final String valueCaption;
  final Color fillLight;
  final Color fillDark;

  @override
  Widget build(BuildContext context) {
    final t = maxForBar <= 0 ? 0.0 : (value / maxForBar).clamp(0.0, 1.0);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      letterSpacing: 0.4,
      color: GameThemeConstants.outlineColor,
      fontSize: 10,
    );
    final valueStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: GameThemeConstants.primaryDark,
      fontSize: 10,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(valueCaption, style: valueStyle),
          ],
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 13,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GameThemeConstants.creamBackground.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: GameThemeConstants.outlineColor,
                    width: GameThemeConstants.outlineThicknessSmall,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: t,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              fillLight,
                              fillDark,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GameThemeConstants.outlineColor.withValues(
                                alpha: 0.12,
                              ),
                              offset: const Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacterListItem extends StatelessWidget {
  const _CharacterListItem({
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: GameThemeConstants.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  SpacingConstants.gameRadiusSm,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.only(top: SpacingConstants.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _buildCharacterAvatar(character)),
              const SizedBox(height: SpacingConstants.xs),
            Text(
              character.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          ),
        ),
      ),
    );
  }
}
