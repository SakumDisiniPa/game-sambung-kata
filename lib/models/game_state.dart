class GameState {
  final String currentPrefix;
  final int score;
  final int timeLeft;
  final bool isGameOver;
  final List<String> players;
  final List<String> eliminatedPlayers;
  final Map<String, int> playerHealth;
  final Map<String, int> playerPBs; // Personal Bests semua pemain
  final int turnChancesLeft;
  final int activePlayerIndex;
  final String? winner;
  final bool isDictionaryLoading;
  final String currentTypedWord;
  final List<String> usedWords;
  final int roundNumber;
  final String lastFeedback;
  final bool isVsComputer;
  final String difficulty;
  final String language;
  final Map<String, int> playerScores;

  GameState({
    this.currentPrefix = 'A',
    this.score = 0,
    this.timeLeft = 13,
    this.isGameOver = false,
    this.players = const [],
    this.eliminatedPlayers = const [],
    this.playerHealth = const {},
    this.playerPBs = const {},
    this.turnChancesLeft = 3,
    this.activePlayerIndex = 0,
    this.winner,
    this.isDictionaryLoading = false,
    this.currentTypedWord = '',
    this.usedWords = const [],
    this.roundNumber = 0,
    this.lastFeedback = '',
    this.isVsComputer = false,
    this.difficulty = 'medium',
    this.language = 'indonesia',
    this.playerScores = const {},
  });

  GameState copyWith({
    String? currentPrefix,
    int? score,
    int? timeLeft,
    bool? isGameOver,
    List<String>? players,
    List<String>? eliminatedPlayers,
    Map<String, int>? playerHealth,
    Map<String, int>? playerPBs,
    int? turnChancesLeft,
    int? activePlayerIndex,
    String? winner,
    bool? isDictionaryLoading,
    String? currentTypedWord,
    List<String>? usedWords,
    int? roundNumber,
    String? lastFeedback,
    bool? isVsComputer,
    String? difficulty,
    String? language,
    Map<String, int>? playerScores,
  }) {
    return GameState(
      currentPrefix: currentPrefix ?? this.currentPrefix,
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
      isGameOver: isGameOver ?? this.isGameOver,
      players: players ?? this.players,
      eliminatedPlayers: eliminatedPlayers ?? this.eliminatedPlayers,
      playerHealth: playerHealth ?? this.playerHealth,
      playerPBs: playerPBs ?? this.playerPBs,
      turnChancesLeft: turnChancesLeft ?? this.turnChancesLeft,
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      winner: winner ?? this.winner,
      isDictionaryLoading: isDictionaryLoading ?? this.isDictionaryLoading,
      currentTypedWord: currentTypedWord ?? this.currentTypedWord,
      usedWords: usedWords ?? this.usedWords,
      roundNumber: roundNumber ?? this.roundNumber,
      lastFeedback: lastFeedback ?? this.lastFeedback,
      isVsComputer: isVsComputer ?? this.isVsComputer,
      difficulty: difficulty ?? this.difficulty,
      language: language ?? this.language,
      playerScores: playerScores ?? this.playerScores,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentPrefix': currentPrefix,
      'score': score,
      'timeLeft': timeLeft,
      'isGameOver': isGameOver,
      'players': List<String>.from(players),
      'eliminatedPlayers': List<String>.from(eliminatedPlayers),
      'playerHealth': Map<String, int>.from(playerHealth),
      'playerPBs': Map<String, int>.from(playerPBs),
      'turnChancesLeft': turnChancesLeft,
      'activePlayerIndex': activePlayerIndex,
      'winner': winner,
      'currentTypedWord': currentTypedWord,
      'usedWords': List<String>.from(usedWords),
      'roundNumber': roundNumber,
      'lastFeedback': lastFeedback,
      'isVsComputer': isVsComputer,
      'difficulty': difficulty,
      'language': language,
      'playerScores': Map<String, int>.from(playerScores),
    };
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      currentPrefix: map['currentPrefix'] as String? ?? 'A',
      score: map['score'] as int? ?? 0,
      timeLeft: map['timeLeft'] as int? ?? 13,
      isGameOver: map['isGameOver'] as bool? ?? false,
      players: List<String>.from(map['players'] ?? []),
      eliminatedPlayers: List<String>.from(map['eliminatedPlayers'] ?? []),
      playerHealth: (map['playerHealth'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
      playerPBs: (map['playerPBs'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
      turnChancesLeft: map['turnChancesLeft'] as int? ?? 3,
      activePlayerIndex: map['activePlayerIndex'] as int? ?? 0,
      winner: map['winner'] as String?,
      isDictionaryLoading: false,
      currentTypedWord: map['currentTypedWord'] as String? ?? '',
      usedWords: List<String>.from(map['usedWords'] ?? []),
      roundNumber: map['roundNumber'] as int? ?? 0,
      lastFeedback: map['lastFeedback'] as String? ?? '',
      isVsComputer: map['isVsComputer'] as bool? ?? false,
      difficulty: map['difficulty'] as String? ?? 'medium',
      language: map['language'] as String? ?? 'indonesia',
      playerScores: (map['playerScores'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          {},
    );
  }
}
