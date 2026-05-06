import 'dart:convert';
import 'package:flutter/services.dart';

class DictionaryService {
  Set<String> _dictionary = {};

  String? _currentLanguage;

  /// Check apakah dictionary sudah di-load
  bool get isLoaded => _dictionary.isNotEmpty;

  String? get currentLanguage => _currentLanguage;

  /// Get semua kata dalam dictionary
  List<String> get allWords => _dictionary.toList();

  /// Load dictionary berdasarkan bahasa
  Future<void> loadDictionary(String language) async {
    // Jika sudah load bahasa yang sama, skip
    if (_dictionary.isNotEmpty && _currentLanguage == language) return;

    try {
      final String fileName = language.toLowerCase() == 'english' 
          ? 'english.txt' 
          : 'indonesia.txt';
      
      final dataString = await rootBundle.loadString('assets/data/$fileName');
      final lines = const LineSplitter().convert(dataString);
      
      _dictionary = lines
          .map((l) => l.trim().toUpperCase())
          .where((l) => l.length > 1)
          .toSet();
      
      _currentLanguage = language;
    } catch (e) {
      // Fallback dictionary jika file tidak ditemukan
      _dictionary = {"AYAM", "BOLA", "KATA", "APPLE", "BOOK", "GAME"};
      _currentLanguage = language;
    }
  }

  /// Validate apakah kata ada di dictionary dan dimulai dengan prefix
  bool isValidWord(String word, String prefix) {
    final upperWord = word.toUpperCase().trim();
    return _dictionary.contains(upperWord) && upperWord.startsWith(prefix);
  }

  /// Get last character dari kata
  String getLastChar(String word) {
    final upperWord = word.toUpperCase().trim();
    return upperWord.substring(upperWord.length - 1);
  }

  /// Mencari prefix dari akhiran kata yang valid (ada di kamus)
  /// Mencoba dari panjang 'targetLength' mengecil ke 1
  String getValidSuffixPrefix(String word, int targetLength) {
    final upperWord = word.toUpperCase().trim();
    
    for (int len = targetLength; len >= 1; len--) {
      if (len > upperWord.length) continue;
      final prefix = upperWord.substring(upperWord.length - len);
      if (hasWordsStartingWith(prefix)) {
        return prefix;
      }
    }
    
    // Fallback jika tidak ada akhiran yang valid, ambil random 1-2 huruf
    return getRandomStartingPrefix(targetLength > 2 ? 2 : 1);
  }

  /// Cek apakah ada minimal satu kata yang dimulai dengan prefix ini
  bool hasWordsStartingWith(String prefix) {
    if (_dictionary.isEmpty) return false;
    final upperPrefix = prefix.toUpperCase().trim();
    // Menggunakan any() lebih cepat daripada where().isNotEmpty
    return _dictionary.any((word) => word.startsWith(upperPrefix));
  }

  /// Ambil awalan acak (1-3 huruf) dari kata acak di kamus
  String getRandomStartingPrefix(int length) {
    if (_dictionary.isEmpty) return "A";
    final randomWord = (_dictionary.toList()..shuffle()).first;
    final len = length.clamp(1, randomWord.length);
    return randomWord.substring(0, len);
  }

  /// Cari semua kata yang dimulai dengan prefix
  List<String> findWordsByPrefix(String prefix) {
    final upperPrefix = prefix.toUpperCase().trim();
    return _dictionary
        .where((word) => word.startsWith(upperPrefix))
        .toList();
  }

  /// Clear dictionary
  void clear() {
    _dictionary.clear();
  }
}
