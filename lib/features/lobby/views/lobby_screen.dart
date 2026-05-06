import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ota_update/ota_update.dart';
import '../../../services/update_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../game/providers/game_logic_provider.dart';
import '../../game/views/game_screen.dart';
import '../providers/lobby_provider.dart';
import '../models/lobby_state.dart';
import '../widgets/lobby_header.dart';
import 'package:permission_handler/permission_handler.dart';

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
    final lobbyState = ref.read(lobbyProvider);
    final lobbyNotifier = ref.read(lobbyProvider.notifier);
    final gameNotifier = ref.read(gameLogicProvider.notifier);

    gameNotifier.setNetworkConfig(lobbyNotifier.gameService, isHost);
    gameNotifier.updatePlayers(lobbyState.connectedPlayers, lobbyState.selectedLanguage);
    gameNotifier.updatePlayerPBs(lobbyNotifier.connectedPlayerPBs);

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
            userName: lobbyState.savedName.isEmpty ? _nameController.text : lobbyState.savedName,
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
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton("BUAT ROOM", Colors.cyanAccent, Colors.black, () {
                  _showLanguageDialog(onSelected: (lang) {
                    lobbyNotifier.createRoom(_nameController.text, lang);
                  });
                }),
                const SizedBox(width: 20),
                _actionButton("JOIN ROOM", Colors.white10, Colors.cyanAccent, () {
                  _showJoinRoomDialog();
                }, hasBorder: true),
              ],
            ),

            const SizedBox(height: 30),

            // VS Computer Button
            ElevatedButton.icon(
              onPressed: () => _showLanguageDialog(onSelected: (lang) {
                _showDifficultyDialog(lang);
              }),
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
              "PB (REKOR KAMU): ${lobbyState.personalHighScore}",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            // Leaderboard Top 3
            if (lobbyState.topPlayers.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                "🏆 TOP PLAYERS 🏆",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orangeAccent.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < lobbyState.topPlayers.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "#${i + 1}",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: i == 0 ? Colors.yellowAccent : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                lobbyState.topPlayers[i]['player'] ?? "Anonim",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              "${lobbyState.topPlayers[i]['score']}",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (i < lobbyState.topPlayers.length - 1)
                        const Divider(color: Colors.white10),
                    ],
                  ],
                ),
              ),
            ],
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
            lobbyState.isHost ? "MENUNGGU LAWAN..." : "MENGHUBUNGKAN KE ROOM: ${lobbyNotifier.lastRoomId}...",
            style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          Text(
            "ROOM ID: ${lobbyNotifier.lastRoomId}",
            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 24),
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
          ElevatedButton.icon(
            onPressed: () {
              final inviteUrl = "https://sambungkata.sakum.my.id/join/${lobbyNotifier.lastRoomId}";
              Clipboard.setData(ClipboardData(text: inviteUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link undangan disalin ke clipboard!")),
              );
            },
            icon: const Icon(Icons.share, color: Colors.black),
            label: const Text("UNDANG TEMAN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
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
                    // Minta izin sebelum memulai update
                    final statuses = await [
                      Permission.storage,
                      Permission.notification,
                    ].request();

                    if (statuses[Permission.storage]!.isDenied) {
                      setDialogState(() {
                        statusText = "Butuh izin penyimpanan!";
                        isDownloading = false;
                      });
                      return;
                    }

                    UpdateService.updateAndroid(info.androidUrl)?.listen(
                      (event) {
                        setDialogState(() {
                          if (event.status == OtaStatus.DOWNLOADING) {
                            // Pakai ?? 0 agar tidak crash jika parsing gagal
                            final val = double.tryParse(event.value ?? '0') ?? 0;
                            progress = val / 100;
                            statusText = "Mendownload: ${event.value}%";
                          } else if (event.status == OtaStatus.INSTALLING) {
                            statusText = "Menyiapkan instalasi...";
                          } else if (event.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR) {
                            statusText = "Izin ditolak! Aktifkan 'Sumber Tidak Dikenal'.";
                            isDownloading = false;
                          } else if (event.status == OtaStatus.INTERNAL_ERROR) {
                            statusText = "Error: ${event.value}";
                            isDownloading = false;
                          }
                        });
                      },
                      onError: (e) {
                        setDialogState(() {
                          statusText = "Gagal: $e";
                          isDownloading = false;
                        });
                      },
                    );
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

  void _showLanguageDialog({required Function(String) onSelected}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.language, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            Text("Pilih Bahasa", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption("INDONESIA", "Gunakan kosa kata Bahasa Indonesia", "🇮🇩", () {
              Navigator.pop(context);
              onSelected('indonesia');
            }),
            const Divider(color: Colors.white10),
            _languageOption("ENGLISH", "Use English vocabulary", "🇺🇸", () {
              Navigator.pop(context);
              onSelected('english');
            }),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String title, String desc, String flag, VoidCallback onTap) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      onTap: onTap,
    );
  }

  void _showDifficultyDialog(String language) {
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
            _difficultyOption("MUDAH", "AI sering salah dan lambat", Colors.greenAccent, 'easy', language),
            const Divider(color: Colors.white10),
            _difficultyOption("NORMAL", "AI cukup menantang", Colors.blueAccent, 'medium', language),
            const Divider(color: Colors.white10),
            _difficultyOption("SULIT", "AI hampir tidak pernah salah", Colors.redAccent, 'hard', language),
          ],
        ),
      ),
    );
  }

  Widget _difficultyOption(String title, String desc, Color color, String diff, String language) {
    return ListTile(
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      onTap: () async {
        if (!mounted) return;
        Navigator.pop(context);
        final lobbyState = ref.read(lobbyProvider);
        final displayName = _nameController.text.isEmpty 
            ? (lobbyState.savedName.isEmpty ? 'Pemain' : lobbyState.savedName) 
            : _nameController.text;
        
        try {
          final lobbyNotifier = ref.read(lobbyProvider.notifier);
          lobbyNotifier.saveName(displayName);
        
          // Matikan koneksi jaringan sebelum main offline lawan komputer
          lobbyNotifier.cancelWaiting(); 

          final gameNotifier = ref.read(gameLogicProvider.notifier);
          gameNotifier.startVsComputer(displayName, diff, language);
          
          // Set PB untuk mode komputer
          final myPB = lobbyState.personalHighScore;
          final compPB = diff == 'easy' ? 500 : (diff == 'medium' ? 2500 : 8000);
          gameNotifier.updatePlayerPBs({displayName: myPB, "Komputer": compPB});
          
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameView(
                playerName: displayName,
                isHost: true,
              ),
            ),
          );
        } catch (e) {
          debugPrint("Error navigation: $e");
        }
      },
    );
  }
  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
        ),
        title: Text("Gabung Room", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan 4 Digit Kode Room lawan kamu", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: _inputDecoration("KODE", Icons.vpn_key),
            ),
            const SizedBox(height: 20),
            _actionButton("GABUNG SEKARANG", Colors.cyanAccent, Colors.black, () {
              if (_idController.text.length < 4) return;
              Navigator.pop(context);
              ref.read(lobbyProvider.notifier).startAutoJoin(_nameController.text, _idController.text, () => _navigateToGame(false));
            }),
          ],
        ),
      ),
    );
  }
}
