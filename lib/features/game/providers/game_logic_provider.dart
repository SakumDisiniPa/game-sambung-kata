import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/local_game_service.dart';
import '../../../models/game_state.dart';
import '../../../services/audio_service.dart';
import '../../../services/dictionary_service.dart';
import '../../../services/game_rules_service.dart';

final gameLogicProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState());

  final AudioService _audioService = AudioService();
  final DictionaryService _dictionaryService = DictionaryService();
  Timer? _timer;

  // Network config
  LocalGameService? _gameService;
  bool _isHost = false;

  bool get isDictionaryLoaded => _dictionaryService.isLoaded;

  void setNetworkConfig(LocalGameService service, bool isHost) {
    _gameService = service;
    _isHost = isHost;
    debugPrint("[GAME] Network config set: isHost=$isHost");
  }

  void _broadcastState() {
    if (!_isHost || _gameService == null) return;
    _gameService!.sendMessage({
      'type': 'game_state_sync',
      ...state.toMap(),
    });
  }

  void applyRemoteState(Map<String, dynamic> data) {
    if (_isHost) return;
    _timer?.cancel();
    final newState = GameState.fromMap(data);
    if (newState.isGameOver && !state.isGameOver) {
      _audioService.playSound('Menang');
    }
    state = newState;
  }

  /// Sinkronkan ketikan ke lawan (dipanggil oleh pemain aktif)
  void updateTyping(String word) {
    state = state.copyWith(currentTypedWord: word);
    if (_gameService != null) {
      _gameService!.sendMessage({
        'type': 'typing_update',
        'word': word,
      });
    }
  }

  /// Terima ketikan dari lawan
  void setTypedWord(String word) {
    state = state.copyWith(currentTypedWord: word);
  }

  void startTimer() {
    _timer?.cancel();
    if (!_isHost) return;
    if (state.players.isEmpty) return;

    state = state.copyWith(timeLeft: GameRulesService.roundTimeSeconds);
    _broadcastState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.players.isEmpty ||
          state.activePlayerIndex >= state.players.length ||
          state.isGameOver) {
        timer.cancel();
        return;
      }

      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        // Waktu habis: kurangi darah, pindah giliran
        final currentPlayer = state.players[state.activePlayerIndex];
        _reduceHealth(currentPlayer);
      }
      _broadcastState();
    });
  }

  /// Kurangi darah player
  void _reduceHealth(String name) {
    if (state.eliminatedPlayers.contains(name)) return;
    if (!state.players.contains(name)) return;

    final newHealth = GameRulesService.reduceHealth(state.playerHealth, name);
    final healthMap = Map<String, int>.from(state.playerHealth);
    healthMap[name] = newHealth;
    state = state.copyWith(playerHealth: healthMap);

    _audioService.playSound('wrong');

    if (GameRulesService.shouldEliminate(newHealth)) {
      _eliminatePlayer(name);
    } else {
      _nextTurn(forceRandomPrefix: true);
    }
  }

  void _eliminatePlayer(String name) {
    if (state.eliminatedPlayers.contains(name)) return;

    final newList = [...state.eliminatedPlayers, name];
    state = state.copyWith(eliminatedPlayers: newList);

    if (GameRulesService.isGameOver(state.players, newList)) {
      _timer?.cancel();
      final winner = GameRulesService.getWinner(state.players, newList);
      state = state.copyWith(isGameOver: true, winner: winner ?? "No One");
      _audioService.playSound('Menang');
      _broadcastState();
    } else {
      _nextTurn(forceRandomPrefix: true);
    }
  }

  void _nextTurn({bool forceRandomPrefix = false}) {
    if (state.players.isEmpty) return;

    final nextIdx = GameRulesService.getNextActivePlayer(
      state.activePlayerIndex,
      state.players,
      state.eliminatedPlayers,
    );

    if (nextIdx >= state.players.length) return;

    String newPrefix = state.currentPrefix;
    if (forceRandomPrefix) {
      final rng = Random();
      int len;
      if (state.roundNumber < 20) {
        len = rng.nextInt(3) + 1;
      } else {
        final chance = rng.nextDouble();
        len = chance < 0.15 ? 2 : rng.nextInt(3) + 3;
      }
      newPrefix = _dictionaryService.getRandomStartingPrefix(len);
    }

    // Reset kesempatan untuk giliran baru
    state = state.copyWith(
      activePlayerIndex: nextIdx,
      turnChancesLeft: GameRulesService.maxTurnChances,
      currentPrefix: newPrefix,
      lastFeedback: '', // Clear feedback
    );
    startTimer();
  }

  Future<void> loadDictionary() async {
    if (_dictionaryService.isLoaded) return;
    state = state.copyWith(isDictionaryLoading: true);
    await _dictionaryService.loadDictionary();
    state = state.copyWith(isDictionaryLoading: false);
  }

  Future<void> submitWord(String word, String? roomId) async {
    if (state.isGameOver || state.isDictionaryLoading) return;
    if (state.players.isEmpty) return;
    if (state.activePlayerIndex >= state.players.length) return;

    // Client: kirim ke host
    if (!_isHost && _gameService != null) {
      _gameService!.sendMessage({
        'type': 'submit_word_request',
        'word': word,
      });
      return;
    }

    // Host: proses lokal
    if (!_dictionaryService.isLoaded) await loadDictionary();

    final upperWord = word.toUpperCase().trim();

    // 1. Cek apakah kata sudah pernah digunakan
    if (state.usedWords.contains(upperWord)) {
      _audioService.playSound('wrong');
      state = state.copyWith(
        lastFeedback: 'KATA SUDAH DIGUNAKAN!',
        turnChancesLeft: state.turnChancesLeft - 1,
      );

      if (state.turnChancesLeft <= 0) {
        _reduceHealth(state.players[state.activePlayerIndex]);
      }
      _broadcastState();
      return;
    }

    // 2. Cek validitas kata (ada di kamus & mulai dengan prefix)
    final isValid = _dictionaryService.isValidWord(word, state.currentPrefix);

    if (isValid) {
      _audioService.playSound('correct');

      // Hitung panjang prefix berikutnya (Random & Progresif)
      final rng = Random();
      int nextPrefixLen;

      if (state.roundNumber < 20) {
        // Awal game (Ronde < 20): Random 1-3 huruf
        nextPrefixLen = rng.nextInt(3) + 1;
      } else {
        // Late game (Ronde >= 20): Dominan 3-5 huruf, kadang 2 huruf
        final chance = rng.nextDouble();
        if (chance < 0.15) {
          nextPrefixLen = 2; // 15% chance for 2 letters
        } else {
          nextPrefixLen = rng.nextInt(3) + 3; // 85% chance for 3, 4, or 5 letters
        }
      }

      final nextPrefix = _dictionaryService.getPrefix(word, nextPrefixLen);

      state = state.copyWith(
        score: state.score + 10,
        currentPrefix: nextPrefix,
        usedWords: [...state.usedWords, upperWord],
        roundNumber: state.roundNumber + 1,
        lastFeedback: '', // Clear feedback
      );
      _nextTurn();
    } else {
      _audioService.playSound('wrong');
      final newChances = state.turnChancesLeft - 1;
      state = state.copyWith(
        turnChancesLeft: newChances,
        lastFeedback: 'KATA TIDAK VALID!',
      );

      if (newChances <= 0) {
        _reduceHealth(state.players[state.activePlayerIndex]);
      }
    }
    _broadcastState();
  }

  void updatePlayers(List<String> players) async {
    final health = {for (var p in players) p: GameRulesService.maxHealth};

    // Jika host, siapkan awalan acak
    String initialPrefix = 'A';
    if (_isHost) {
      if (!_dictionaryService.isLoaded) await _dictionaryService.loadDictionary();
      // Random length 1-3 untuk awal permainan
      final randomLen = Random().nextInt(3) + 1;
      initialPrefix = _dictionaryService.getRandomStartingPrefix(randomLen);
    }

    state = state.copyWith(
      players: players,
      playerHealth: health,
      turnChancesLeft: GameRulesService.maxTurnChances,
      activePlayerIndex: 0,
      isGameOver: false,
      eliminatedPlayers: [],
      usedWords: [],
      roundNumber: 0,
      currentPrefix: initialPrefix,
      lastFeedback: '',
    );
  }

  void resetGame() {
    _timer?.cancel();
    state = GameState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
