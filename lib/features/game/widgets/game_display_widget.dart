import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/game_state.dart';

class GameDisplayWidget extends StatelessWidget {
  final GameState gameState;
  final String currentPlayerName;

  const GameDisplayWidget({
    super.key,
    required this.gameState,
    required this.currentPlayerName,
  });

  @override
  Widget build(BuildContext _) {
    if (gameState.isGameOver) {
      return _buildGameOverScreen();
    }

    if (gameState.players.isEmpty) {
      return const SizedBox();
    }

    return _buildActiveGameScreen();
  }

  Widget _buildGameOverScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "GAME OVER",
          style: GoogleFonts.outfit(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "WINNER",
          style: TextStyle(color: Colors.white54, letterSpacing: 2),
        ),
        Text(
          gameState.winner ?? "No One",
          style: GoogleFonts.outfit(
            fontSize: 40,
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveGameScreen() {
    // Safety: bounds check
    if (gameState.activePlayerIndex >= gameState.players.length) {
      return const SizedBox();
    }

    final activePlayerName = gameState.players[gameState.activePlayerIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          activePlayerName == currentPlayerName
              ? "GILIRAN KAMU!"
              : "GILIRAN: $activePlayerName",
          style: GoogleFonts.outfit(
            fontSize: 22,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          gameState.currentPrefix,
          style: GoogleFonts.outfit(
            fontSize: 130,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
            shadows: [
              Shadow(color: Colors.cyan.withAlpha(150), blurRadius: 30),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "${gameState.timeLeft}s",
          style: GoogleFonts.outfit(
            fontSize: 35,
            color: gameState.timeLeft < 10 ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
