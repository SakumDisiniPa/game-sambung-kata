import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/local_game_service.dart';
import '../../../models/game_state.dart';
import '../../../services/sound_service.dart';
import '../../../services/dictionary_service.dart';
import '../../../services/game_rules_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/storage_service.dart';

final gameLogicProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier();
});

class GameNotifier extends StateNotifier<GameState> {
  GameNotifier() : super(GameState()) {
    _aiService = AIService(_dictionaryService);
  }

  final SoundService _soundService = SoundService();
  final DictionaryService _dictionaryService = DictionaryService();
  late final AIService _aiService;
  Timer? _aiThinkingTimer;
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
      _soundService.playSFX('Menang');
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

    // Cek jika giliran komputer
    if (state.isVsComputer && state.players[state.activePlayerIndex] == "Komputer") {
      _triggerAI();
    }
  }

  void _triggerAI() {
    _aiThinkingTimer?.cancel();
    final delay = _aiService.getThinkingDelay(state.difficulty);
    
    _aiThinkingTimer = Timer(delay, () async {
      if (state.isGameOver || 
          state.activePlayerIndex >= state.players.length ||
          state.players[state.activePlayerIndex] != "Komputer") {
        return;
      }
      
      String? word = _aiService.pickWord(state.currentPrefix, state.difficulty, state.usedWords);
      
      bool isConfusion = false;
      
      // Jika AI tidak nemu kata, atau akurasi gagal (pickWord balikin hasil pickWrongWord internally)
      // Kita cek apakah kata yang dipilih valid. Kalau nggak valid, berarti itu confusion.
      if (word == null || !_dictionaryService.isValidWord(word, state.currentPrefix)) {
        isConfusion = true;
        if (word == null) {
          final rng = Random();
          word = state.currentPrefix + String.fromCharCodes(Iterable.generate(rng.nextInt(3)+2, (_) => rng.nextInt(26) + 97));
        }
      }
      
      await _simulateAITyping(word, isConfusion: isConfusion);
      
      if (!isConfusion) {
        submitWord(word, null);
      }
    });
  }

  Future<void> _simulateAITyping(String word, {bool isConfusion = false}) async {
    final rng = Random();
    final difficulty = state.difficulty;
    final baseSpeed = _aiService.getTypingBaseSpeed(difficulty);
    
    String currentText = "";
    
    // Probabilitas typo per karakter
    // Easy: sering typo (15%), Hard: jarang (2%)
    double typoChance = 0.08;
    if (difficulty == 'easy') typoChance = 0.15;
    if (difficulty == 'hard') typoChance = 0.02;
    const String keys = "abcdefghijklmnopqrstuvwxyz";

    for (int i = 0; i < word.length; i++) {
      if (state.isGameOver || 
          state.activePlayerIndex >= state.players.length ||
          state.players[state.activePlayerIndex] != "Komputer") {
        return;
      }
      
      // Simulasi Typo
      if (rng.nextDouble() < typoChance && i > 0) {
        // Pilih huruf acak buat typo
        String wrongChar = keys[rng.nextInt(keys.length)];
        if (wrongChar == word[i].toLowerCase()) {
          wrongChar = 'x'; // Just a fallback
        }
        
        // Ketik yang salah
        currentText += wrongChar;
        updateTyping(currentText);
        await Future.delayed(Duration(milliseconds: rng.nextInt(150) + 100));
        
        // Jeda bentar pas sadar salah (realization delay)
        await Future.delayed(Duration(milliseconds: rng.nextInt(300) + 200));
        
        // Hapus yang salah (backspace)
        currentText = currentText.substring(0, currentText.length - 1);
        updateTyping(currentText);
        await Future.delayed(Duration(milliseconds: rng.nextInt(100) + 100));
      }

      // Ketik yang bener
      currentText += word[i];
      updateTyping(currentText);
      
      // Delay ketik antar karakter (ada variasi biar manusiawi)
      final variation = rng.nextInt(baseSpeed ~/ 2);
      final typingDelay = Duration(milliseconds: baseSpeed + variation);
      await Future.delayed(typingDelay);
    }
    
    // Jika sedang bingung/confusion, tunggu bentar terus hapus semua (simulasi nyerah)
    if (isConfusion) {
      await Future.delayed(const Duration(milliseconds: 800));
      for (int i = currentText.length; i > 0; i--) {
        currentText = currentText.substring(0, i - 1);
        updateTyping(currentText);
        await Future.delayed(Duration(milliseconds: baseSpeed ~/ 2));
      }
    }
    
    if (state.isGameOver || 
        state.activePlayerIndex >= state.players.length ||
        state.players[state.activePlayerIndex] != "Komputer") {
      return;
    }
        
    await Future.delayed(Duration(milliseconds: rng.nextInt(300) + 300));
    submitWord(word, null);
  }

  /// Kurangi darah player
  void _reduceHealth(String name) {
    if (state.eliminatedPlayers.contains(name)) return;
    if (!state.players.contains(name)) return;

    final newHealth = GameRulesService.reduceHealth(state.playerHealth, name);
    final healthMap = Map<String, int>.from(state.playerHealth);
    healthMap[name] = newHealth;
    state = state.copyWith(playerHealth: healthMap);

    _soundService.playSFX('wrong');

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
      _soundService.playSFX('Menang');

      // Update skor akhir
      final finalScores = Map<String, int>.from(state.playerScores);
      final rng = Random();
      
      // Pemenang dapat bonus besar
      if (winner != null) {
        finalScores[winner] = (finalScores[winner] ?? 0) + rng.nextInt(901) + 600;
      }
      
      // Yang kalah (yang baru saja dieliminasi) dikurangi poin
      finalScores[name] = (finalScores[name] ?? 0) - (rng.nextInt(401) + 100);

      state = state.copyWith(playerScores: finalScores);
      
      // Simpan high score pemain lokal
      final myName = state.players.isNotEmpty ? state.players[0] : null; // Asumsi player 0 adalah local user
      if (myName != null) {
        StorageService().saveHighScore(finalScores[myName] ?? 0);
      }
      
      _broadcastState();
    } else {
      // Belum game over, tapi pemain ini kalah ronde (tereliminasi)
      final finalScores = Map<String, int>.from(state.playerScores);
      finalScores[name] = (finalScores[name] ?? 0) - (Random().nextInt(401) + 100);
      state = state.copyWith(playerScores: finalScores);
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
      _soundService.playSFX('wrong');
      state = state.copyWith(
        lastFeedback: 'KATA SUDAH DIGUNAKAN!',
        turnChancesLeft: state.turnChancesLeft - 1,
      );

      if (state.turnChancesLeft <= 0) {
        _reduceHealth(state.players[state.activePlayerIndex]);
      } else if (state.isVsComputer && state.players[state.activePlayerIndex] == "Komputer") {
        // Trigger lagi kalau masih ada nyawa (kesempatan)
        _triggerAI();
      }
      _broadcastState();
      return;
    }

    // 2. Cek validitas kata (ada di kamus & mulai dengan prefix)
    final isValid = _dictionaryService.isValidWord(word, state.currentPrefix);

    if (isValid) {
      _soundService.playSFX('correct');

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

      final newScores = Map<String, int>.from(state.playerScores);
      final currentPlayer = state.players[state.activePlayerIndex];
      newScores[currentPlayer] = (newScores[currentPlayer] ?? 0) + rng.nextInt(551) + 50;

      state = state.copyWith(
        playerScores: newScores,
        currentPrefix: nextPrefix,
        usedWords: [...state.usedWords, upperWord],
        roundNumber: state.roundNumber + 1,
        lastFeedback: '', // Clear feedback
      );
      _nextTurn();
    } else {
      _soundService.playSFX('wrong');
      final newChances = state.turnChancesLeft - 1;
      state = state.copyWith(
        turnChancesLeft: newChances,
        lastFeedback: 'KATA TIDAK VALID!',
      );

      if (newChances <= 0) {
        _reduceHealth(state.players[state.activePlayerIndex]);
      } else if (state.isVsComputer && state.players[state.activePlayerIndex] == "Komputer") {
        // Trigger lagi kalau masih ada nyawa (kesempatan)
        _triggerAI();
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
      playerScores: {for (var p in players) p: 0},
    );
  }

  void startVsComputer(String playerName, String difficulty) async {
    _isHost = true; // Anggap sebagai host untuk proses lokal
    if (!_dictionaryService.isLoaded) await _dictionaryService.loadDictionary();
    
    final players = [playerName, "Komputer"];
    final health = {for (var p in players) p: GameRulesService.maxHealth};
    
    final randomLen = Random().nextInt(3) + 1;
    final initialPrefix = _dictionaryService.getRandomStartingPrefix(randomLen);

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
      isVsComputer: true,
      difficulty: difficulty,
      playerScores: {for (var p in players) p: 0},
    );
    
    startTimer();
  }

  void resetGame() {
    _timer?.cancel();
    state = GameState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _aiThinkingTimer?.cancel();
    super.dispose();
  }
}
