import 'dart:math';

class GameRulesService {
  static const int maxHealth = 4; // Darah maksimal
  static const int maxTurnChances = 3; // Kesempatan per giliran
  static const int roundTimeSeconds = 13;

  /// Calculate next active player (skip eliminated players)
  static int getNextActivePlayer(
    int currentIndex,
    List<String> players,
    List<String> eliminatedPlayers,
  ) {
    if (players.isEmpty) return 0;

    int nextIdx = (currentIndex + 1) % players.length;
    int attempts = 0;
    while (eliminatedPlayers.contains(players[nextIdx])) {
      nextIdx = (nextIdx + 1) % players.length;
      attempts++;
      if (attempts >= players.length) break;
    }
    return nextIdx;
  }

  /// Get remaining players (not eliminated)
  static List<String> getRemainingPlayers(
    List<String> players,
    List<String> eliminatedPlayers,
  ) {
    return players.where((p) => !eliminatedPlayers.contains(p)).toList();
  }

  /// Check if game is over (only 1 or fewer players remain)
  static bool isGameOver(List<String> players, List<String> eliminatedPlayers) {
    final remaining = getRemainingPlayers(players, eliminatedPlayers);
    return remaining.length <= 1;
  }

  /// Get winner (last remaining player)
  static String? getWinner(
    List<String> players,
    List<String> eliminatedPlayers,
  ) {
    final remaining = getRemainingPlayers(players, eliminatedPlayers);
    return remaining.isNotEmpty ? remaining.first : null;
  }

  /// Reduce health, return new health value
  static int reduceHealth(Map<String, int> playerHealth, String playerName) {
    return ((playerHealth[playerName] ?? maxHealth) - 1).clamp(0, maxHealth);
  }

  /// Check if player should be eliminated (health <= 0)
  static bool shouldEliminate(int health) {
    return health <= 0;
  }

  /// Hitung panjang prefix berikutnya secara progresif (Max 5)
  static int getNextPrefixLength(int roundNumber) {
    final rng = Random();
    if (roundNumber < 10) {
      return rng.nextInt(2) + 1; // Ronde awal: 1-2 huruf
    } else if (roundNumber < 25) {
      return rng.nextInt(3) + 1; // Mulai panas: 1-3 huruf
    } else if (roundNumber < 45) {
      return rng.nextInt(3) + 2; // Menengah: 2-4 huruf
    } else {
      return rng.nextInt(3) + 3; // Late game: 3-5 huruf (Max 5)
    }
  }
}
