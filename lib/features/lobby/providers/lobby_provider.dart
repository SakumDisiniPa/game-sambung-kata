import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/network/local_game_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/storage_service.dart';
import '../../game/providers/game_logic_provider.dart';
import '../../../services/update_service.dart';
import '../models/lobby_state.dart';

final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  return LobbyNotifier(ref);
});

class LobbyNotifier extends StateNotifier<LobbyState> {
  final Ref ref;
  final LocalGameService _gameService = LocalGameService();
  final SoundService _soundService = SoundService();
  final StorageService _storageService = StorageService();
  StreamSubscription? _messageSubscription;

  LobbyNotifier(this.ref) : super(LobbyState()) {
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    final savedName = await _storageService.getName();
    final highScore = await _storageService.getHighScore();
    
    state = state.copyWith(
      appVersion: "v${info.version}+${info.buildNumber}",
      savedName: savedName ?? '',
      highScore: highScore,
    );

    _soundService.playBGM('lobby.wav');

    _messageSubscription = _gameService.messages.listen(_handleMessages);

    // Cek Update Otomatis
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final update = await UpdateService.checkForUpdate();
    if (update != null) {
      state = state.copyWith(availableUpdate: update);
    }
  }

  void _handleMessages(Map<String, dynamic> data) {
    if (data['type'] == 'join' && state.isHost) {
      final newPlayers = [...state.connectedPlayers];
      if (!newPlayers.contains(data['name'])) {
        newPlayers.add(data['name']);
        state = state.copyWith(connectedPlayers: newPlayers);
      }
      _gameService.sendMessage({
        "type": "player_list",
        "players": newPlayers,
        "host": state.myHostName,
      });

      if (newPlayers.length >= 2) {
        // Trigger navigation signal via state if needed, 
        // but for now we'll keep the direct navigation logic in the View 
        // or add a 'shouldNavigate' flag to state.
      }
    } else if (data['type'] == 'player_list' && !state.isHost) {
      state = state.copyWith(
        connectedPlayers: List<String>.from(data['players']),
        myHostName: data['host'] ?? state.myHostName,
      );
    } else if (data['type'] == 'game_state_sync' && !state.isHost) {
      ref.read(gameLogicProvider.notifier).applyRemoteState(data);
    } else if (data['type'] == 'submit_word_request' && state.isHost) {
      final word = data['word'] as String?;
      if (word != null) {
        ref.read(gameLogicProvider.notifier).submitWord(word, null);
      }
    } else if (data['type'] == 'typing_update') {
      final word = data['word'] as String? ?? '';
      ref.read(gameLogicProvider.notifier).setTypedWord(word);
    }
  }

  void toggleMute() {
    final newMute = !state.isMuted;
    state = state.copyWith(isMuted: newMute);
    _soundService.setBGMMute(newMute);
  }

  Future<void> saveName(String name) async {
    await _storageService.saveName(name);
    state = state.copyWith(savedName: name);
  }

  Future<void> createRoom(String name, String roomId) async {
    if (name.isEmpty || roomId.isEmpty) return;
    await saveName(name);
    await _gameService.startHost(roomId);
    state = state.copyWith(
      isWaiting: true,
      isHost: true,
      myHostName: name,
      connectedPlayers: [name],
    );
  }

  void startAutoJoin(String name, String roomId, VoidCallback onFound) {
    if (name.isEmpty || roomId.isEmpty) return;
    saveName(name);
    state = state.copyWith(isWaiting: true, isHost: false);
    
    _gameService.startSearching(roomId, (room) {
      if (!state.isWaiting) return;
      _gameService.joinRoom(room.ip, room.port, name);
      onFound();
    });
  }

  void cancelWaiting() {
    _gameService.stop();
    state = state.copyWith(isWaiting: false, connectedPlayers: []);
  }

  void stopBGM() => _soundService.stopBGM();

  /// Ambil ulang skor tertinggi dari storage (dipanggil pas game over)
  Future<void> refreshHighScore() async {
    final highScore = await _storageService.getHighScore();
    state = state.copyWith(highScore: highScore);
  }

  LocalGameService get gameService => _gameService;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _gameService.stop();
    super.dispose();
  }
}
