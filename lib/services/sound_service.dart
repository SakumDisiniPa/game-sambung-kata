import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isBGMMuted = false;

  /// Setup & Play BGM (Music)
  Future<void> playBGM(String fileName, {double volume = 0.5}) async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(
      AssetSource('audio/$fileName'), 
      volume: _isBGMMuted ? 0 : volume
    );
  }

  /// Toggle Mute untuk BGM saja
  Future<void> setBGMMute(bool mute) async {
    _isBGMMuted = mute;
    await _bgmPlayer.setVolume(mute ? 0 : 0.5);
  }

  /// Stop BGM
  Future<void> stopBGM() async {
    await _bgmPlayer.stop();
  }

  /// Play SFX (Effects) - Tidak terpengaruh mute BGM
  void playSFX(String name) {
    String fileName = name.toLowerCase();
    
    if (fileName == 'correct') {
      fileName = 'benar.mp3';
    } else if (fileName == 'wrong') {
      fileName = 'salah.wav';
    } else {
      // Menang, Kalah, dsb
      fileName = '$fileName.mp3';
    }
    
    // SFX selalu play di volume normal (1.0)
    _sfxPlayer.play(AssetSource('audio/$fileName'), volume: 1.0);
  }

  /// Dispose all players
  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
