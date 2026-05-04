import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Putar sound effect berdasarkan nama
  void playSound(String name) {
    String fileName = name == 'correct'
        ? 'Benar.mp3'
        : (name == 'wrong' ? 'Salah.wav' : '$name.mp3');
    _audioPlayer.play(AssetSource('audio/$fileName'));
  }

  /// Set volume audio (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// Putar background music dengan loop
  Future<void> playBackgroundMusic(
    String assetPath, {
    double volume = 0.5,
  }) async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(assetPath), volume: volume);
  }

  /// Stop audio
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  /// Dispose audio player
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
