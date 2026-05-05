import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';
import '../../../services/update_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/providers/game_logic_provider.dart';
import '../../game/views/game_screen.dart';
import '../providers/lobby_provider.dart';
import '../models/lobby_state.dart';
import '../widgets/lobby_header.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Sinkronkan nama dari state awal
    Future.microtask(() {
      final savedName = ref.read(lobbyProvider).savedName;
      if (savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
    });

    _nameController.addListener(() {
      ref.read(lobbyProvider.notifier).saveName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _navigateToGame(bool isHost) {
    final lobbyNotifier = ref.read(lobbyProvider.notifier);
    final gameNotifier = ref.read(gameLogicProvider.notifier);

    gameNotifier.setNetworkConfig(lobbyNotifier.gameService, isHost);
    gameNotifier.updatePlayers(ref.read(lobbyProvider).connectedPlayers);

    gameNotifier.loadDictionary().then((_) {
      if (!mounted) return;
      if (isHost) gameNotifier.startTimer();
      lobbyNotifier.stopBGM();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameView(
            playerName: _nameController.text,
            isHost: isHost,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lobbyState = ref.watch(lobbyProvider);
    final lobbyNotifier = ref.read(lobbyProvider.notifier);

    // Watch for player list changes to auto-start if host
    ref.listen(lobbyProvider, (prev, next) {
      if (next.isHost && next.connectedPlayers.length >= 2 && (prev?.connectedPlayers.length ?? 0) < 2) {
        _navigateToGame(true);
      }
    });

    // Watch for updates
    ref.listen(lobbyProvider, (prev, next) {
      if (next.availableUpdate != null && prev?.availableUpdate == null) {
        _showUpdateDialog(next.availableUpdate!);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withAlpha(150)),

          SafeArea(
            child: lobbyState.isWaiting ? _buildWaitingLobby(lobbyState, lobbyNotifier) : _buildMainLobby(lobbyState, lobbyNotifier),
          ),

          // Header Bar
          LobbyHeader(
            isMuted: lobbyState.isMuted,
            onMuteToggle: lobbyNotifier.toggleMute,
            userName: _nameController.text,
          ),
        ],
      ),
    );
  }

  Widget _buildMainLobby(LobbyState lobbyState, LobbyNotifier lobbyNotifier) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              "SAMBUNG KATA",
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.cyanAccent,
              ),
            ),
            const Text(
              "Global Online Edition",
              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 50),
            
            // Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration("Nama Kamu", Icons.person),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("KODE ROOM (Misal: 1234)", Icons.vpn_key),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton("BUAT ROOM", Colors.cyanAccent, Colors.black, () {
                  lobbyNotifier.createRoom(_nameController.text, _idController.text);
                }),
                const SizedBox(width: 20),
                _actionButton("JOIN ROOM", Colors.white10, Colors.cyanAccent, () {
                  lobbyNotifier.startAutoJoin(_nameController.text, _idController.text, () => _navigateToGame(false));
                }, hasBorder: true),
              ],
            ),

            const SizedBox(height: 30),

            // VS Computer Button
            ElevatedButton.icon(
              onPressed: () => _showDifficultyDialog(),
              icon: const Icon(Icons.computer_rounded),
              label: const Text("LAWAN KOMPUTER"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent.withAlpha(30),
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(color: Colors.orangeAccent),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),

            const SizedBox(height: 50),
            
            Text(
              "SKOR TERTINGGI: ${lobbyState.highScore}",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.cyanAccent.withAlpha(150),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              lobbyState.appVersion,
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Widget _actionButton(String label, Color bg, Color fg, VoidCallback onPressed, {bool hasBorder = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        side: hasBorder ? const BorderSide(color: Colors.cyanAccent) : null,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildWaitingLobby(LobbyState lobbyState, LobbyNotifier lobbyNotifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 30),
          Text(
            lobbyState.isHost ? "MENUNGGU LAWAN..." : "MENGHUBUNGKAN KE ROOM: ${_idController.text}...",
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            "ROOM ID: ${_idController.text}",
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          if (lobbyState.connectedPlayers.isNotEmpty) ...[
            const Text("PEMAIN TERHUBUNG:", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 15),
            ...lobbyState.connectedPlayers.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(p, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          ],
          const SizedBox(height: 50),
          TextButton.icon(
            onPressed: () => lobbyNotifier.cancelWaiting(),
            icon: const Icon(Icons.close, color: Colors.redAccent),
            label: const Text("BATALKAN", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(UpdateInfo info) {
    double? progress;
    String statusText = info.changelog;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Colors.cyanAccent),
                const SizedBox(width: 12),
                Text("Update Tersedia!", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Versi ${info.version}", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      statusText,
                      style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: progress, color: Colors.cyanAccent, backgroundColor: Colors.white10),
                ],
              ],
            ),
            actions: [
              if (!isDownloading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("NANTI SAJA", style: GoogleFonts.outfit(color: Colors.white38)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isDownloading ? null : () async {
                  setDialogState(() {
                    isDownloading = true;
                    statusText = "Memulai update...";
                  });

                  if (Platform.isAndroid) {
                    UpdateService.updateAndroid(info.androidUrl)?.listen((event) {
                      setDialogState(() {
                        if (event.status == OtaStatus.DOWNLOADING) {
                          progress = double.tryParse(event.value ?? '0')! / 100;
                          statusText = "Mendownload: ${event.value}%";
                        } else if (event.status == OtaStatus.INSTALLING) {
                          statusText = "Menyiapkan instalasi...";
                        }
                      });
                    });
                  } else {
                    final url = Platform.isLinux ? info.linuxUrl : info.windowsUrl;
                    try {
                      await UpdateService.updateDesktop(url, (status) {
                        setDialogState(() {
                          statusText = status;
                        });
                      });
                    } catch (e) {
                      setDialogState(() {
                        isDownloading = false;
                        statusText = "Gagal: $e";
                      });
                    }
                  }
                },
                child: Text(isDownloading ? "MENGUNDUH..." : "UPDATE SEKARANG", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: const BorderSide(color: Colors.white10),
        ),
        title: Text("Pilih Tingkat Kesulitan", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _difficultyOption("MUDAH", "AI sering salah dan lambat", Colors.greenAccent, 'easy'),
            const Divider(color: Colors.white10),
            _difficultyOption("NORMAL", "AI cukup menantang", Colors.blueAccent, 'medium'),
            const Divider(color: Colors.white10),
            _difficultyOption("SULIT", "AI hampir tidak pernah salah", Colors.redAccent, 'hard'),
          ],
        ),
      ),
    );
  }

  Widget _difficultyOption(String title, String desc, Color color, String diff) {
    return ListTile(
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      onTap: () async {
        if (!mounted) return;
        Navigator.pop(context);
        if (_nameController.text.isEmpty) return;
        
        ref.read(lobbyProvider.notifier).saveName(_nameController.text);
        ref.read(gameLogicProvider.notifier).startVsComputer(_nameController.text, diff);
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameView(
              playerName: _nameController.text,
              isHost: true,
            ),
          ),
        );
      },
    );
  }
}
