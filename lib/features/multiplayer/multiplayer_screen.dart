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
      body: Container(
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
                        SegmentedButton<MultiplayerRole>(
                          segments: const [
                            ButtonSegment(
                              value: MultiplayerRole.market,
                              label: Text('Market'),
                              icon: Icon(Icons.trending_up),
                            ),
                            ButtonSegment(
                              value: MultiplayerRole.investor,
                              label: Text('Investor'),
                              icon: Icon(Icons.person),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (selection) {
                            setState(() => _selectedRole = selection.first);
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
                            border: OutlineInputBorder(),
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
    );
  }
}
