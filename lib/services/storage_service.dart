import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyName = 'user_name';
  static const String _keyHighScore = 'high_score';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Simpan Nama User
  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  /// Ambil Nama User
  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  /// Simpan High Score
  Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    int currentHigh = prefs.getInt(_keyHighScore) ?? 0;
    if (score > currentHigh) {
      await prefs.setInt(_keyHighScore, score);
    }
  }

  /// Ambil High Score
  Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
  }
}
