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
}
