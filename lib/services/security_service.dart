import 'dart:convert';
import 'dart:typed_data';

class SecurityService {
  // Kunci enkripsi sederhana (Bisa diubah sesuka hati)
  static const String _secretKey = "SAMKUM_SUPER_SECRET_2026";

  /// Mengubah String menjadi Binary yang terenkripsi (XOR)
  static Uint8List encrypt(String text) {
    final List<int> bytes = utf8.encode(text);
    final List<int> keyBytes = utf8.encode(_secretKey);
    final List<int> encrypted = [];

    for (int i = 0; i < bytes.length; i++) {
      encrypted.add(bytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return Uint8List.fromList(encrypted);
  }

  /// Mengubah Binary terenkripsi kembali menjadi String
  static String decrypt(Uint8List encryptedBytes) {
    final List<int> keyBytes = utf8.encode(_secretKey);
    final List<int> decrypted = [];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(decrypted);
  }
}
