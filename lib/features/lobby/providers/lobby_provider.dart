import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_links/app_links.dart';
import '../../../core/network/local_game_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/user_storage_service.dart';
import '../../../services/update_service.dart';
import '../../game/providers/game_logic_provider.dart';
import '../models/lobby_state.dart';

final lobbyProvider = StateNotifierProvider<LobbyNotifier, LobbyState>((ref) {
  return LobbyNotifier(ref);
});

class LobbyNotifier extends StateNotifier<LobbyState> {
  final Ref ref;
  final LocalGameService _gameService = LocalGameService();
  final SoundService _soundService = SoundService();
  final UserStorageService _storageService = UserStorageService();
  final _appLinks = AppLinks();
  StreamSubscription? _messageSubscription;
  StreamSubscription? _linkSubscription;
  final Map<String, int> _connectedPlayerPBs = {};

  LobbyNotifier(this.ref) : super(LobbyState()) {
    _init();
  }

  Future<void> _init() async {
    final info = await PackageInfo.fromPlatform();
    final savedName = await _storageService.getUserName();
    final cachedGlobal = await _storageService.getCachedGlobalHighScore();
    final cachedPersonal = await _storageService.getPersonalHighScore();
    
    state = state.copyWith(
      appVersion: "v${info.version}+${info.buildNumber}",
      savedName: savedName ?? 'Pemain',
      globalHighScore: cachedGlobal,
      personalHighScore: cachedPersonal,
    );

    _soundService.playBGM('lobby.wav');

    // Koneksi ke server default
    await joinGlobalLobby();

    _messageSubscription = _gameService.messages.listen(_handleMessages);

    // Cek Deep Link saat startup dan saat berjalan
    _initDeepLinks();

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
    if (data['type'] == 'leaderboard_update') {
      final list = List<Map<String, dynamic>>.from(data['topPlayers']);
      state = state.copyWith(
        topPlayers: list,
        globalHighScore: list.isNotEmpty ? list[0]['score'] : 0,
      );
      if (list.isNotEmpty) {
        _storageService.saveUserData(name: state.savedName, globalHighScore: list[0]['score']);
      }
    } else if (data['type'] == 'join' && state.isHost) {
      // ... (rest of the handle messages)
      // ... (existing logic)
      String newPlayerName = data['name'];
      int playerPB = data['pb'] ?? 0;
      final newPlayers = [...state.connectedPlayers];
      
      // Jika nama sama, tambahkan angka di belakangnya agar tidak konflik di UI
      int count = 1;
      String originalName = newPlayerName;
      while (newPlayers.contains(newPlayerName)) {
        count++;
        newPlayerName = "$originalName ($count)";
      }

      newPlayers.add(newPlayerName);
      _connectedPlayerPBs[newPlayerName] = playerPB;
      state = state.copyWith(connectedPlayers: newPlayers);
      
      _gameService.sendMessage({
        "type": "player_list",
        "players": newPlayers,
        "playerPBs": _connectedPlayerPBs,
        "host": state.myHostName,
        "language": state.selectedLanguage,
      });

      if (newPlayers.length >= 2) {
        // Trigger navigation signal via state if needed, 
        // but for now we'll keep the direct navigation logic in the View 
        // or add a 'shouldNavigate' flag to state.
      }
    } else if (data['type'] == 'player_list' && !state.isHost) {
      final players = List<String>.from(data['players']);
      final pbs = Map<String, int>.from(data['playerPBs'] ?? {});
      state = state.copyWith(
        connectedPlayers: players,
        myHostName: data['host'] ?? state.myHostName,
        selectedLanguage: data['language'] ?? state.selectedLanguage,
      );
      _connectedPlayerPBs.addAll(pbs);
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
    } else if (data['type'] == 'player_left') {
      ref.read(gameLogicProvider.notifier).handlePlayerDisconnected(data['player']);
    }
  }

  void toggleMute() {
    final newMute = !state.isMuted;
    state = state.copyWith(isMuted: newMute);
    _soundService.setBGMMute(newMute);
  }

  Future<void> saveName(String name) async {
    await _storageService.saveUserData(name: name);
    state = state.copyWith(savedName: name);
  }

  Future<void> createRoom(String name, String language) async {
    try {
      final effectiveName = name.isEmpty ? (state.savedName.isEmpty ? 'Pemain' : state.savedName) : name;
      
      // Bikin ID 4 Digit Acak
      final rng = Random();
      final randomRoomId = (rng.nextInt(9000) + 1000).toString();
      _lastRoomId = randomRoomId;

      // Update state SECEPAT MUNGKIN agar UI berubah
      state = state.copyWith(
        isWaiting: true,
        isHost: true,
        myHostName: effectiveName,
        connectedPlayers: [effectiveName],
        selectedLanguage: language,
        savedName: effectiveName,
      );

      await saveName(effectiveName);
      
      _connectedPlayerPBs.clear();
      _connectedPlayerPBs[effectiveName] = state.personalHighScore;

      // Urusan network jangan sampai nge-block UI
      await _gameService.stop().catchError((_) => null);
      await _gameService.joinRoom(randomRoomId, 8000, effectiveName).catchError((_) => null);
    } catch (e) {
      debugPrint("Error createRoom: $e");
    }
  }

  String _lastRoomId = "";
  String get lastRoomId => _lastRoomId;

  void startAutoJoin(String name, String roomId, VoidCallback onFound) {
    final effectiveName = name.isEmpty ? state.savedName : name;
    _lastRoomId = roomId;

    saveName(effectiveName);
    state = state.copyWith(
      isWaiting: true, 
      isHost: false,
      savedName: effectiveName,
    );
    
    // Langsung konek ke VPS menggunakan Room ID
    _gameService.joinRoom(roomId, 8000, effectiveName).then((_) {
      if (!state.isWaiting) return;
      
      // Kirim PB kita ke host
      _gameService.sendMessage({
        "type": "join",
        "name": effectiveName,
        "pb": state.personalHighScore,
      });

      onFound();
    });
  }

  void cancelWaiting() {
    _gameService.stop();
    state = state.copyWith(isWaiting: false, connectedPlayers: []);
    // Konek balik ke lobby utama buat liat leaderboard
    joinGlobalLobby();
  }

  void stopBGM() => _soundService.stopBGM();

  Map<String, int> get connectedPlayerPBs => _connectedPlayerPBs;

  /// Ambil ulang skor tertinggi dan sinkronkan ke server
  Future<void> refreshHighScore() async {
    // Reload personal best dari lokal skm
    final personal = await _storageService.getPersonalHighScore();
    state = state.copyWith(personalHighScore: personal);
    
    // Langsung kirim ke server biar sinkron (nampak di leaderboard)
    final userId = await _storageService.getUserId();
    _gameService.sendMessage({
      "type": "sync_profile",
      "userId": userId,
      "player": state.savedName,
      "score": personal,
    });
  }

  Future<void> joinGlobalLobby() async {
    await _gameService.joinRoom("global_lobby", 8000, state.savedName);
    
    // Sinkronisasi data ke server
    final userId = await _storageService.getUserId();
    _gameService.sendMessage({
      "type": "sync_profile",
      "userId": userId,
      "player": state.savedName,
      "score": state.personalHighScore,
    });
  }

  LocalGameService get gameService => _gameService;

  void _initDeepLinks() {
    // 1. Cek link saat aplikasi dibuka dari kondisi mati (Cold Start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // 2. Cek link saat aplikasi sedang berjalan di background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep Link masuk: $uri");
    String? roomId;

    if (uri.scheme == 'sambungkata') {
      // Format: sambungkata://join/1234
      if (uri.host == 'join') {
        roomId = uri.path.replaceAll('/', '');
      }
    } else {
      // Format: https://play.sambungkata.sakum.my.id/join/1234
      if (uri.pathSegments.contains('join')) {
        final index = uri.pathSegments.indexOf('join');
        if (index + 1 < uri.pathSegments.length) {
          roomId = uri.pathSegments[index + 1];
        }
      }
      // Format Cadangan buat Web: https://play.sambungkata.sakum.my.id/?join=1234
      if (roomId == null && uri.queryParameters.containsKey('join')) {
        roomId = uri.queryParameters['join'];
      }
    }

    if (roomId != null && roomId.length == 4) {
      // Tunggu sebentar biar inisialisasi selesai, baru join
      Future.delayed(const Duration(seconds: 1), () {
        startAutoJoin(state.savedName, roomId!, () {
          // Berhasil join
        });
      });
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _linkSubscription?.cancel();
    _gameService.stop();
    super.dispose();
  }
}
