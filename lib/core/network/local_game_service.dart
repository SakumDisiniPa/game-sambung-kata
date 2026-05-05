import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/game_room.dart';

class LocalGameService {
  static const String vpsBaseUrl = "wss://api.sakum.my.id";

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // Untuk Online, kita tidak butuh server lokal atau UDP
  Future<String?> startHost(String roomId) async {
    return _connect(roomId, "Host");
  }

  void broadcast(String message) {
    // Di mode Online (Relay), kita hanya perlu mengirim ke server, 
    // server yang akan membagikan ke orang lain.
    _channel?.sink.add(message);
  }

  Future<void> startSearching(
    String targetId,
    Function(GameRoom) onFound,
  ) async {
    // Di mode Online, kita langsung "tembak" room-nya saja
    // Kita anggap room selalu ditemukan jika koneksi berhasil
    onFound(GameRoom(id: targetId, ip: "vps", port: 8000));
  }

  Future<void> stopDiscovery() async {
    // Tidak ada lagi UDP yang perlu distop
  }

  Future<void> joinRoom(String roomId, int port, String myName) async {
    // Parameter port diabaikan karena kita pakai port 8000 dari VPS
    await _connect(roomId, myName);
  }

  Future<String?> _connect(String roomId, String myName) async {
    try {
      final url = '$vpsBaseUrl/$roomId';
      debugPrint("Connecting to Online Room: $url");
      
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      // Tunggu sebentar untuk memastikan koneksi berhasil (opsional)
      // Kita dengarkan stream-nya
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _messageController.add(data);
          } catch (e) {
            debugPrint("Error decoding message: $e");
          }
        },
        onDone: () {
          debugPrint("Disconnected from VPS Server");
        },
        onError: (error) {
          debugPrint("WebSocket Error: $error");
        },
      );

      // Kirim identitas awal
      sendMessage({"type": "join", "name": myName, "roomId": roomId});
      
      return "online:$roomId";
    } catch (e) {
      debugPrint("Connect Fail: $e");
      return null;
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    final msg = jsonEncode(data);
    _channel?.sink.add(msg);
  }

  Future<void> stop() async {
    await _channel?.sink.close();
    _channel = null;
  }
}

