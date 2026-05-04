import 'dart:convert';
import 'package:flutter/services.dart';

class DictionaryService {
  Set<String> _dictionary = {};

  /// Check apakah dictionary sudah di-load
  bool get isLoaded => _dictionary.isNotEmpty;

  /// Load dictionary dari CSV
  Future<void> loadDictionary() async {
    if (_dictionary.isNotEmpty) return;

    try {
      final csvString = await rootBundle.loadString(
        'assets/data/datasetinternasional.csv',
      );
      final lines = const LineSplitter().convert(csvString);
      _dictionary = lines
          .skip(1)
          .map((l) => l.trim().toUpperCase())
          .where((l) => l.length > 1)
          .toSet();
    } catch (e) {
      // Fallback dictionary jika CSV tidak ditemukan
      _dictionary = {"AYAM", "BOLA", "KATA"};
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

  /// Get prefix dari akhir kata dengan panjang tertentu
  /// Untuk sistem prefix progresif (1-3 huruf)
  String getPrefix(String word, int length) {
    final upperWord = word.toUpperCase().trim();
    final len = length.clamp(1, upperWord.length);
    return upperWord.substring(upperWord.length - len);
  }

  /// Ambil awalan acak (1-3 huruf) dari kata acak di kamus
  String getRandomStartingPrefix(int length) {
    if (_dictionary.isEmpty) return "A";
    final randomWord = (_dictionary.toList()..shuffle()).first;
    final len = length.clamp(1, randomWord.length);
    return randomWord.substring(0, len);
  }

  /// Clear dictionary
  void clear() {
    _dictionary.clear();
  }
}
