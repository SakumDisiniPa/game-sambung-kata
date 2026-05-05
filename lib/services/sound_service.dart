import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isBGMMuted = false;
  bool _isPlaying = false;
  
  // Playlist Management
  List<String> _inGamePlaylist = [];
  int _currentSongIndex = -1;
  String _currentSongName = "";

  // Getters for UI
  bool get isPlaying => _isPlaying;
  String get currentSongName => _currentSongName;
  Stream<Duration> get onPositionChanged => _bgmPlayer.onPositionChanged;
  Stream<Duration> get onDurationChanged => _bgmPlayer.onDurationChanged;

  /// Setup Playlist
  void setPlaylist(List<String> songs) {
    _inGamePlaylist = songs;
  }

  /// Play Music from Playlist
  Future<void> playPlaylist({bool random = true}) async {
    if (_inGamePlaylist.isEmpty) return;
    
    if (random) {
      _currentSongIndex = Random().nextInt(_inGamePlaylist.length);
    } else {
      _currentSongIndex = 0;
    }
    
    await _playCurrentIndex();
  }

  /// Toggle Mute untuk BGM
  Future<void> setBGMMute(bool mute) async {
    _isBGMMuted = mute;
    await _bgmPlayer.setVolume(mute ? 0 : 0.5);
  }

  Future<void> _playCurrentIndex() async {
    if (_currentSongIndex < 0 || _currentSongIndex >= _inGamePlaylist.length) return;
    
    _currentSongName = _inGamePlaylist[_currentSongIndex];
    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.release); // Jangan loop, biar bisa ganti lagu pas abis
    
    // Otomatis putar lagu berikutnya kalau lagu ini habis
    _bgmPlayer.onPlayerComplete.listen((event) {
      nextSong();
    });

    await _bgmPlayer.play(
      AssetSource('audio/ingame/$_currentSongName'),
      volume: _isBGMMuted ? 0 : 0.5
    );
    _isPlaying = true;
  }

  Future<void> nextSong() async {
    if (_inGamePlaylist.isEmpty) return;
    _currentSongIndex = (_currentSongIndex + 1) % _inGamePlaylist.length;
    await _playCurrentIndex();
  }

  Future<void> prevSong() async {
    if (_inGamePlaylist.isEmpty) return;
    _currentSongIndex = (_currentSongIndex - 1 + _inGamePlaylist.length) % _inGamePlaylist.length;
    await _playCurrentIndex();
  }

  Future<void> togglePause() async {
    if (_isPlaying) {
      await _bgmPlayer.pause();
      _isPlaying = false;
    } else {
      await _bgmPlayer.resume();
      _isPlaying = true;
    }
  }

  /// Original playBGM (for Lobby)
  Future<void> playBGM(String fileName, {double volume = 0.5}) async {
    await _bgmPlayer.stop();
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(
      AssetSource('audio/$fileName'), 
      volume: _isBGMMuted ? 0 : 0.3
    );
    _currentSongName = fileName;
    _isPlaying = true;
  }

  Future<void> stopBGM() async {
    await _bgmPlayer.stop();
    _isPlaying = false;
  }

  void playSFX(String name) {
    String fileName = name.toLowerCase();
    if (fileName == 'correct') {
      fileName = 'benar.mp3';
    } else if (fileName == 'wrong') {
      fileName = 'salah.wav';
    } else {
      fileName = '$fileName.mp3';
    }
    _sfxPlayer.play(AssetSource('audio/$fileName'), volume: 0.6);
  }

  /// Play suara ketikan random (typing1 atau typing2)
  void playTypingSFX() {
    final rng = Random();
    final file = rng.nextBool() ? 'typing1.wav' : 'typing2.wav';
    _sfxPlayer.play(AssetSource('audio/$file'), volume: 0.4);
  }

  Future<void> dispose() async {
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
