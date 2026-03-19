import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/character_image_constants.dart';
import 'package:start_hack_2026/core/constants/character_neutral_stats.dart';
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

const Map<String, String> _statDisplayNames = {
  'money': 'Money',
  'riskTolerance': 'Risk Tolerance',
  'financialKnowledge': 'Financial Knowledge',
  'assetSlots': 'Asset Slots',
  'monthlySavings': 'Monthly Savings',
  'emotionalReaction': 'Emotional Reaction',
  'knowledge': 'Knowledge',
  'investmentHorizonRemaining': 'Investment Horizon',
  'savingsRate': 'Savings Rate',
  'behavioralBias': 'Behavioral Bias',
};

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
                          onStatDisplayName: (id) =>
                              _statDisplayNames[id] ?? id,
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

class _SelectedCharacterSlot extends StatelessWidget {
  const _SelectedCharacterSlot({
    required this.selectedCharacter,
    required this.onStatDisplayName,
  });

  final Character? selectedCharacter;
  final String Function(String id) onStatDisplayName;

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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Center(child: _buildCharacterAvatar(character)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: SpacingConstants.xs),
                  child: Text(
                    character.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GameThemeConstants.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingConstants.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...character.initialStats.entries
                    .where(
                      (entry) => CharacterNeutralStats.differsFromNeutral(
                        entry.key,
                        entry.value,
                      ),
                    )
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: SpacingConstants.xs,
                        ),
                        child: Text(
                          '${onStatDisplayName(entry.key)}: ${_formatStatValue(entry.key, entry.value)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: GameThemeConstants.primaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      );
                    }),
                const SizedBox(height: SpacingConstants.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingConstants.sm,
                    vertical: SpacingConstants.xs,
                  ),
                  decoration: BoxDecoration(
                    color: GameThemeConstants.accentLight.withValues(
                      alpha: 0.3,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: GameThemeConstants.outlineColorLight,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatValue(String statId, num value) {
    if (statId == 'money') {
      return '\$${value.toStringAsFixed(0)}';
    }
    return value.toStringAsFixed(0);
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
    );
  }
}
