import 'package:audioplayers/audioplayers.dart';

class LobbyService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Setup background music untuk lobby
  Future<void> setupLobbyMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/Lobby.wav'), volume: 0.5);
  }

  /// Toggle mute
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Stop music
  Future<void> stopMusic() async {
    await _audioPlayer.stop();
  }

  /// Dispose
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
