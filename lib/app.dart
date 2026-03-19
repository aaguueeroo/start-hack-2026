import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:start_hack_2026/core/constants/app_constants.dart';
import 'package:start_hack_2026/core/theme/game_theme.dart';
import 'package:start_hack_2026/data/loaders/json_data_loader.dart';
import 'package:start_hack_2026/data/mock/mock_game_repository.dart';
import 'package:start_hack_2026/engine/game_engine.dart';
import 'package:start_hack_2026/features/achievements/achievements_screen.dart';
import 'package:start_hack_2026/features/character_selection/character_selection_screen.dart';
import 'package:start_hack_2026/features/home/home_screen.dart';
import 'package:start_hack_2026/features/leaderboard/leaderboard_screen.dart';
import 'package:start_hack_2026/features/simulation/simulation_screen.dart';
import 'package:start_hack_2026/features/store/store_screen.dart';
import 'package:start_hack_2026/modules/game/controllers/game_controller.dart';
import 'package:start_hack_2026/modules/simulation/controllers/simulation_controller.dart';
import 'package:start_hack_2026/modules/store/controllers/store_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<JsonDataLoader>(create: (_) => JsonDataLoader()),
        Provider<MockGameRepository>(
          create: (context) => MockGameRepository(
            jsonDataLoader: context.read<JsonDataLoader>(),
          ),
        ),
        Provider<GameEngine>(create: (_) => GameEngine()),
        ChangeNotifierProvider<GameController>(
          create: (context) => GameController(
            gameRepository: context.read<MockGameRepository>(),
            gameEngine: context.read<GameEngine>(),
          ),
        ),
        ChangeNotifierProvider<StoreController>(
          create: (context) => StoreController(
            gameRepository: context.read<MockGameRepository>(),
            gameEngine: context.read<GameEngine>(),
          ),
        ),
        ChangeNotifierProvider<SimulationController>(
          create: (context) => SimulationController(
            gameEngine: context.read<GameEngine>(),
            gameRepository: context.read<MockGameRepository>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: GameTheme.light,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/character-selection',
      builder: (context, state) => const CharacterSelectionScreen(),
    ),
    GoRoute(path: '/store', builder: (context, state) => const StoreScreen()),
    GoRoute(
      path: '/simulation',
      builder: (context, state) => const SimulationScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
  ],
);
