import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'security_service.dart';

class UserStorageService {
  static const String _fileName = 'user.skm';
  static const String _webKey = 'skm_user_data';

  static final UserStorageService _instance = UserStorageService._internal();
  factory UserStorageService() => _instance;
  UserStorageService._internal();

  Future<File?> _getUserFile() async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<bool> hasUserData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_webKey);
    }
    final file = await _getUserFile();
    return await file!.exists();
  }

  Future<void> saveUserData({
    String? name,
    int? personalHighScore,
    int? globalHighScore,
    String? userId,
  }) async {
    final oldData = await _readRawData();
    
    final dataMap = {
      'name': name ?? (oldData['name'] ?? 'Pemain'),
      'personalHighScore': personalHighScore ?? (oldData['personalHighScore'] ?? 0),
      'globalHighScore': globalHighScore ?? (oldData['globalHighScore'] ?? 0),
      'userId': userId ?? (oldData['userId'] ?? _generateRandomId()),
    };

    final jsonData = jsonEncode(dataMap);

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey, jsonData);
    } else {
      final file = await _getUserFile();
      final encryptedData = SecurityService.encrypt(jsonData);
      await file!.writeAsBytes(encryptedData);
    }
  }

  Future<Map<String, dynamic>> _readRawData() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonData = prefs.getString(_webKey);
        if (jsonData == null) return {};
        return jsonDecode(jsonData) as Map<String, dynamic>;
      } else {
        final file = await _getUserFile();
        if (!await file!.exists()) return {};
        final encryptedBytes = await file.readAsBytes();
        final decryptedString = SecurityService.decrypt(encryptedBytes);
        return jsonDecode(decryptedString) as Map<String, dynamic>;
      }
    } catch (e) {
      return {};
    }
  }

  Future<String?> getUserName() async {
    final data = await _readRawData();
    return data['name'] as String?;
  }

  Future<int> getCachedGlobalHighScore() async {
    final data = await _readRawData();
    return (data['globalHighScore'] as int?) ?? 0;
  }

  Future<int> getPersonalHighScore() async {
    final data = await _readRawData();
    return (data['personalHighScore'] as int?) ?? 0;
  }

  Future<String> getUserId() async {
    final data = await _readRawData();
    if (data['userId'] == null) {
      final newId = _generateRandomId();
      await saveUserData(name: data['name'], userId: newId);
      return newId;
    }
    return data['userId'] as String;
  }

  String _generateRandomId() {
    final rng = Random();
    return "USER_${rng.nextInt(900000) + 100000}_${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<void> clearUserData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webKey);
    } else {
      final file = await _getUserFile();
      if (await file!.exists()) {
        await file.delete();
      }
    }
  }
}
