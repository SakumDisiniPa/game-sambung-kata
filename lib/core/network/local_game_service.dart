import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/game_room.dart';

class LocalGameService {
  static const int udpPort = 45451;

  HttpServer? _server;
  RawDatagramSocket? _udpHostSocket;
  Timer? _broadcastTimer;
  final List<WebSocketChannel> _clients = [];

  WebSocketChannel? _clientChannel;
  RawDatagramSocket? _udpClientSocket;
  bool _hasJoined = false; // Flag: sudah konek belum?
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  final StreamController<GameRoom> _discoveryController =
      StreamController.broadcast();
  Stream<GameRoom> get discoveredRooms => _discoveryController.stream;

  Future<String?> startHost(String roomId) async {
    String? myIp;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254')) {
            myIp = addr.address;
            break;
          }
        }
        if (myIp != null) break;
      }
    } catch (e) {
      debugPrint("IP Error: $e");
    }

    myIp ??= await NetworkInfo().getWifiIP();
    if (myIp == null) return null;

    await stop();

    var handler = webSocketHandler((dynamic webSocket, dynamic protocol) {
      final channel = webSocket as WebSocketChannel;
      _clients.add(channel);
      channel.stream.listen((message) {
        final data = jsonDecode(message);
        _messageController.add(data);
      }, onDone: () => _clients.remove(channel));
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);
    final port = _server!.port;

    _udpHostSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpHostSocket!.broadcastEnabled = true;

    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final msg = "SK_ID|$roomId|$myIp|$port";
      _udpHostSocket?.send(
        utf8.encode(msg),
        InternetAddress("255.255.255.255"),
        udpPort,
      );
    });

    return "$myIp:$port";
  }

  void broadcast(String message) {
    for (var client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        debugPrint("Broadcast error: $e");
      }
    }
  }

  Future<void> startSearching(
    String targetId,
    Function(GameRoom) onFound,
  ) async {
    await stopDiscovery();
    _hasJoined = false; // Reset flag
    try {
      _udpClientSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpPort,
      );
      _udpClientSocket!.listen((RawSocketEvent event) {
        if (_hasJoined) return; // Sudah konek, abaikan broadcast berikutnya
        if (event == RawSocketEvent.read) {
          final datagram = _udpClientSocket!.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data).trim();
            if (msg.startsWith("SK_ID|")) {
              final parts = msg.split('|');
              if (parts.length == 4 && parts[1] == targetId) {
                _hasJoined = true; // Tandai: sudah ketemu, jangan konek lagi!
                stopDiscovery(); // Matiin radar
                onFound(
                  GameRoom(
                    id: parts[1],
                    ip: parts[2],
                    port: int.parse(parts[3]),
                  ),
                );
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Radar Error: $e");
    }
  }

  Future<void> stopDiscovery() async {
    _udpClientSocket?.close();
    _udpClientSocket = null;
  }

  Future<void> joinRoom(String ip, int port, String myName) async {
    return _connect(ip, port, myName);
  }

  Future<void> _connect(String host, int port, String myName) async {
    try {
      final url = 'ws://$host:$port';
      _clientChannel = WebSocketChannel.connect(Uri.parse(url));
      _clientChannel!.stream.listen(
        (message) {
          _messageController.add(jsonDecode(message));
        },
        onDone: () {
          debugPrint("Disconnected from Host");
        },
      );
      sendMessage({"type": "join", "name": myName});
    } catch (e) {
      debugPrint("Connect Fail: $e");
    }
  }

  void sendMessage(Map<String, dynamic> data) {
    final msg = jsonEncode(data);
    if (_server != null) {
      // Sebagai Host, simpan/proses secara lokal dan kirim ke semua client
      _messageController.add(data);
      broadcast(msg);
    } else {
      // Sebagai Client, kirim ke Host
      _clientChannel?.sink.add(msg);
    }
  }

  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _udpHostSocket?.close();
    _udpHostSocket = null;
    _hasJoined = false;
    await stopDiscovery();
    await _server?.close();
    await _clientChannel?.sink.close();
    _clients.clear();
  }
}
