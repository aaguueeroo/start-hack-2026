import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/game_theme_constants.dart';
import 'package:start_hack_2026/core/constants/spacing_constants.dart';
import 'package:start_hack_2026/core/widgets/game_button.dart';
import 'package:start_hack_2026/core/widgets/game_card.dart';
import 'package:start_hack_2026/domain/entities/multiplayer.dart';
import 'package:start_hack_2026/modules/multiplayer/controllers/multiplayer_controller.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  MultiplayerRole _selectedRole = MultiplayerRole.market;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MultiplayerController>().initializeCatalog();
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom(MultiplayerController controller) async {
    final ok = await controller.createRoom(_selectedRole);
    if (!mounted || !ok) return;
    context.push('/multiplayer/room');
  }

  Future<void> _joinRoom(MultiplayerController controller) async {
    final code = _roomCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a room code.')));
      return;
    }

    final ok = await controller.joinRoom(roomCode: code);
    if (!mounted || !ok) return;
    context.push('/multiplayer/room');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multiplayer')),
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GameThemeConstants.creamBackground, Color(0xFFF5EDE0)],
            ),
          ),
          child: Consumer<MultiplayerController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(SpacingConstants.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!controller.isAvailable)
                    const GameCard(
                      child: Text(
                        'Supabase is not configured. Add SUPABASE_URL and '
                        'SUPABASE_ANON_KEY to use multiplayer.',
                      ),
                    ),
                  if (controller.errorMessage != null) ...[
                    GameCard(
                      child: Text(
                        controller.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: GameThemeConstants.dangerDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: SpacingConstants.md),
                  ],
                  GameCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Your Role (Room Creator)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        _CartoonRoleToggle(
                          selectedRole: _selectedRole,
                          onRoleChanged: (MultiplayerRole role) {
                            setState(() => _selectedRole = role);
                          },
                        ),
                        const SizedBox(height: SpacingConstants.md),
                        Text(
                          'Create Room',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        Text(
                          'Second player gets the other available role.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        GameButton(
                          label: controller.isBusy
                              ? 'Creating...'
                              : 'Create New Room',
                          icon: Icons.add,
                          variant: GameButtonVariant.primary,
                          onPressed:
                              controller.isBusy || !controller.isAvailable
                              ? null
                              : () => _createRoom(controller),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SpacingConstants.md),
                  GameCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Join Room',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        Text(
                          'Role is assigned automatically based on who is '
                          'already in the room.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        TextField(
                          controller: _roomCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'Room code (e.g. AB12CD)',
                          ),
                        ),
                        const SizedBox(height: SpacingConstants.sm),
                        GameButton(
                          label: controller.isBusy
                              ? 'Joining...'
                              : 'Join Existing Room',
                          icon: Icons.login,
                          variant: GameButtonVariant.accent,
                          onPressed:
                              controller.isBusy || !controller.isAvailable
                              ? null
                              : () => _joinRoom(controller),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}

class _CartoonRoleToggle extends StatefulWidget {
  const _CartoonRoleToggle({
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final MultiplayerRole selectedRole;
  final ValueChanged<MultiplayerRole> onRoleChanged;

  @override
  State<_CartoonRoleToggle> createState() => _CartoonRoleToggleState();
}

class _CartoonRoleToggleState extends State<_CartoonRoleToggle>
    with SingleTickerProviderStateMixin {
  static const Duration _thumbDuration = Duration(milliseconds: 280);
  static const Color _marketBevel = Color(0xFF008F82);
  static const Color _investorBevel = Color(0xFF3D2E8C);

  late AnimationController _thumbPositionController;

  @override
  void initState() {
    super.initState();
    _thumbPositionController = AnimationController(
      vsync: this,
      duration: _thumbDuration,
      value: widget.selectedRole == MultiplayerRole.market ? 0.0 : 1.0,
    );
  }

  @override
  void didUpdateWidget(covariant _CartoonRoleToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRole != widget.selectedRole) {
      _thumbPositionController.animateTo(
        widget.selectedRole == MultiplayerRole.market ? 0.0 : 1.0,
        duration: _thumbDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _thumbPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GameThemeConstants.creamBackground.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(GameThemeConstants.radiusPill),
        border: Border.all(
          color: GameThemeConstants.outlineColor,
          width: GameThemeConstants.outlineThickness,
        ),
        boxShadow: [
          BoxShadow(
            color: GameThemeConstants.outlineColor.withValues(alpha: 0.18),
            offset: const Offset(0, GameThemeConstants.bevelOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackW = constraints.maxWidth;
          const double gap = SpacingConstants.xs;
          if (trackW <= 0) {
            return const SizedBox(height: 48);
          }
          final double segmentW = (trackW - gap) / 2.0;
          return ClipRRect(
            borderRadius: BorderRadius.circular(GameThemeConstants.radiusPill),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedBuilder(
                  animation: _thumbPositionController,
                  builder: (BuildContext context, Widget? child) {
                    final double t = _thumbPositionController.value;
                    final Color top = Color.lerp(
                      GameThemeConstants.accentLight,
                      GameThemeConstants.primaryLight,
                      t,
                    )!;
                    final Color bottom = Color.lerp(
                      GameThemeConstants.accentDark,
                      GameThemeConstants.primaryDark,
                      t,
                    )!;
                    final Color bevel = Color.lerp(
                      _marketBevel,
                      _investorBevel,
                      t,
                    )!;
                    final double thumbLeft = t * (segmentW + gap);
                    return Positioned(
                      left: thumbLeft,
                      top: 0,
                      bottom: 0,
                      width: segmentW,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [top, bottom],
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
                              color: bevel,
                              offset:
                                  const Offset(0, GameThemeConstants.bevelOffset),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: _RoleTabTapTarget(
                        label: 'Market',
                        icon: Icons.trending_up_rounded,
                        isSelected:
                            widget.selectedRole == MultiplayerRole.market,
                        splashSeed: GameThemeConstants.accentLight,
                        onTap: () =>
                            widget.onRoleChanged(MultiplayerRole.market),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _RoleTabTapTarget(
                        label: 'Investor',
                        icon: Icons.person_rounded,
                        isSelected:
                            widget.selectedRole == MultiplayerRole.investor,
                        splashSeed: GameThemeConstants.primaryLight,
                        onTap: () =>
                            widget.onRoleChanged(MultiplayerRole.investor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleTabTapTarget extends StatelessWidget {
  const _RoleTabTapTarget({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.splashSeed,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color splashSeed;
  final VoidCallback onTap;

  static List<Shadow> _cartoonLabelShadows() {
    return const [
      Shadow(
        color: GameThemeConstants.outlineColor,
        offset: Offset(1.5, 1.5),
        blurRadius: 0,
      ),
      Shadow(
        color: GameThemeConstants.outlineColor,
        offset: Offset(-1, -1),
        blurRadius: 0,
      ),
      Shadow(
        color: GameThemeConstants.outlineColor,
        offset: Offset(1, -1),
        blurRadius: 0,
      ),
      Shadow(
        color: GameThemeConstants.outlineColor,
        offset: Offset(-1, 1),
        blurRadius: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ) ??
        const TextStyle(fontWeight: FontWeight.w800);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(GameThemeConstants.radiusButtonStadium),
        splashColor: splashSeed.withValues(alpha: 0.35),
        highlightColor: splashSeed.withValues(alpha: 0.14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingConstants.sm + 2,
            horizontal: SpacingConstants.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : GameThemeConstants.darkNavy,
              ),
              const SizedBox(width: SpacingConstants.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: baseStyle.copyWith(
                    color:
                        isSelected ? Colors.white : GameThemeConstants.darkNavy,
                    shadows: isSelected ? _cartoonLabelShadows() : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
