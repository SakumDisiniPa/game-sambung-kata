import 'dart:math';
import 'dictionary_service.dart';

class AIService {
  final DictionaryService _dictionaryService;
  final Random _random = Random();

  AIService(this._dictionaryService);

  /// Menentukan delay berpikir berdasarkan difficulty
  Duration getThinkingDelay(String difficulty) {
    switch (difficulty) {
      case 'easy':
        // 4-7 detik
        return Duration(seconds: _random.nextInt(4) + 4);
      case 'hard':
        // 1-2 detik
        return Duration(seconds: _random.nextInt(2) + 1);
      case 'medium':
      default:
        // 2-4 detik
        return Duration(seconds: _random.nextInt(3) + 2);
    }
  }

  /// Menentukan kecepatan mengetik (ms per karakter)
  int getTypingBaseSpeed(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 250; // Pelan (Manusia santai)
      case 'hard':
        return 80;  // Gacor (Pro player)
      case 'medium':
      default:
        return 150; // Sedang
    }
  }

  /// Memilih kata berdasarkan difficulty
  String? pickWord(String prefix, String difficulty, List<String> usedWords) {
    final possibleWords = _dictionaryService.findWordsByPrefix(prefix);
    
    // Filter kata yang sudah digunakan
    final availableWords = possibleWords
        .where((w) => !usedWords.contains(w.toUpperCase()))
        .toList();

    if (availableWords.isEmpty) return null;

    // Logika akurasi (kemungkinan komputer "bingung")
    double accuracy;
    switch (difficulty) {
      case 'easy':
        accuracy = 0.65; // 65% benar
        break;
      case 'hard':
        accuracy = 0.98; // 98% benar
        break;
      case 'medium':
      default:
        accuracy = 0.85; // 85% benar
        break;
    }

    if (_random.nextDouble() > accuracy) {
      // 70% chance ngetik kata salah (bingung), 30% chance timeout
      return _random.nextDouble() < 0.7 ? pickWrongWord(prefix, usedWords) : null;
    }

    // Filter berdasarkan panjang kata sesuai difficulty
    List<String> filteredWords;
    switch (difficulty) {
      case 'easy':
        // Cari kata pendek (2-4 huruf) - Bahasa Indonesia dasar
        filteredWords = availableWords.where((w) => w.length <= 4).toList();
        break;
      case 'hard':
        // Cari kata panjang (7+ huruf) untuk menyulitkan player
        filteredWords = availableWords.where((w) => w.length >= 7).toList();
        break;
      case 'medium':
      default:
        // Kata sedang (4-7 huruf)
        filteredWords = availableWords.where((w) => w.length >= 4 && w.length <= 7).toList();
        break;
    }

    // Jika filter terlalu ketat, ambil dari yang tersedia saja
    if (filteredWords.isEmpty) {
      filteredWords = availableWords;
    }

    // Ambil acak dari list yang sudah difilter
    filteredWords.shuffle();
    return filteredWords.first;
  }

  /// Memilih kata yang salah (untuk simulasi kebingungan)
  String? pickWrongWord(String currentPrefix, List<String> usedWords) {
    // Cari kata yang TIDAK mulai dengan prefix
    final allWords = _dictionaryService.allWords;
    if (allWords.isEmpty) return null;

    final wrongWords = allWords
        .where((w) => !w.toUpperCase().startsWith(currentPrefix.toUpperCase()) && !usedWords.contains(w.toUpperCase()))
        .toList();

    if (wrongWords.isEmpty) return allWords[_random.nextInt(allWords.length)];
    
    wrongWords.shuffle();
    return wrongWords.first;
  }
}
