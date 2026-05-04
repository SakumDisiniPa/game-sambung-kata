import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/game/providers/game_logic_provider.dart';
import 'core/network/local_game_service.dart';
import 'features/game/views/game_screen.dart';
import 'services/lobby_service.dart';

void main() {
  runApp(const ProviderScope(child: SambungKataApp()));
}

class SambungKataApp extends StatelessWidget {
  const SambungKataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const LobbyView(),
    );
  }
}

class LobbyView extends ConsumerStatefulWidget {
  // Fix: Jadi Consumer
  const LobbyView({super.key});

  @override
  ConsumerState<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends ConsumerState<LobbyView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final LobbyService _lobbyService = LobbyService();

  final LocalGameService _gameService = LocalGameService();
  final List<String> _connectedPlayers = [];
  bool _isWaiting = false;
  bool _isHost = false;
  bool _isMuted = false;
  String _myHostName = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _lobbyService.setupLobbyMusic();

    _gameService.messages.listen((data) {
      if (!mounted) return;

      if (data['type'] == 'join' && _isHost) {
        setState(() {
          if (!_connectedPlayers.contains(data['name'])) {
            _connectedPlayers.add(data['name']);
          }
        });
        _gameService.sendMessage({
          "type": "player_list",
          "players": List<String>.from(_connectedPlayers),
          "host": _myHostName,
        });

        if (_connectedPlayers.length >= 2) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            _navigateToGame(true);
          });
        }
      } else if (data['type'] == 'player_list' && !_isHost) {
        setState(() {
          _connectedPlayers.clear();
          _connectedPlayers.addAll(List<String>.from(data['players']));
          if (data['host'] != null) _myHostName = data['host'];
        });
      } else if (data['type'] == 'start_game' && !_isHost) {
        _navigateToGame(false);
      } else if (data['type'] == 'game_state_sync' && !_isHost) {
        // Client terima state update dari host
        ref.read(gameLogicProvider.notifier).applyRemoteState(data);
      } else if (data['type'] == 'submit_word_request' && _isHost) {
        // Host terima word submission dari client
        final word = data['word'] as String?;
        if (word != null) {
          ref.read(gameLogicProvider.notifier).submitWord(word, null);
        }
      } else if (data['type'] == 'typing_update') {
        // Terima update ketikan dari lawan
        final word = data['word'] as String? ?? '';
        ref.read(gameLogicProvider.notifier).setTypedWord(word);
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _lobbyService.setVolume(_isMuted ? 0 : 0.5);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lobbyService.dispose();
    _nameController.dispose();
    _idController.dispose();
    _gameService.stop();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) return;
    await _gameService.startHost(_idController.text);
    setState(() {
      _isWaiting = true;
      _isHost = true;
      _myHostName = _nameController.text;
      _connectedPlayers.clear();
      _connectedPlayers.add(_nameController.text);
    });
  }

  void _startAutoJoin() {
    if (_nameController.text.isEmpty || _idController.text.isEmpty) return;
    setState(() {
      _isWaiting = true;
      _isHost = false;
    });
    _gameService.startSearching(_idController.text, (room) {
      if (!_isWaiting) return;
      _gameService.joinRoom(room.ip, room.port, _nameController.text);
    });
  }

  void _navigateToGame(bool isHostInitiated) {
    if (_connectedPlayers.isEmpty) {
      debugPrint("[GAME] ABORT: _connectedPlayers is empty!");
      return;
    }

    if (isHostInitiated) {
      _gameService.sendMessage({"type": "start_game"});
    }

    debugPrint(
      "[GAME] Initializing game with ${_connectedPlayers.length} players: $_connectedPlayers (isHost: $_isHost)",
    );

    final notifier = ref.read(gameLogicProvider.notifier);
    // Set network config SEBELUM update players
    notifier.setNetworkConfig(_gameService, _isHost);
    notifier.updatePlayers(_connectedPlayers);

    // Load dictionary, lalu start game
    notifier
        .loadDictionary()
        .then((_) {
          if (!mounted) return;

          debugPrint("[GAME] Dictionary loaded, navigating... (isHost: $_isHost)");

          // Hanya HOST yang start timer (client terima state dari host)
          if (_isHost) {
            notifier.startTimer();
          }

          // Stop lobby music
          _lobbyService.stopMusic();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameView(
                playerName: _nameController.text,
                isHost: _isHost,
              ),
            ),
          );
        })
        .catchError((e) {
          debugPrint("[GAME] Error loading dictionary: $e");
          if (!mounted) return;

          if (_isHost) {
            notifier.startTimer();
          }

          _lobbyService.stopMusic();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameView(
                playerName: _nameController.text,
                isHost: _isHost,
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
            child: _isWaiting ? _buildWaitingLobby() : _buildMainLobby(),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white10,
              onPressed: _toggleMute,
              child: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.cyanAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainLobby() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
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
              "P2P Manual ID Edition",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Nama Kamu",
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.cyanAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "KODE ROOM (Misal: 1234)",
                      prefixIcon: const Icon(
                        Icons.vpn_key,
                        color: Colors.cyanAccent,
                      ),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _createRoom,
                  child: const Text(
                    "BUAT ROOM",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  onPressed: _startAutoJoin,
                  child: const Text(
                    "JOIN ROOM",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingLobby() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.cyanAccent),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withAlpha(30),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent),
            ),
            child: Column(
              children: [
                const Text(
                  "KODE ROOM AKTIF",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.cyanAccent,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _idController.text,
                  style: GoogleFonts.outfit(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Menunggu Lawan... (${_connectedPlayers.length}/2)",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: _connectedPlayers.map((p) {
              final isThisPlayerHost = p == _myHostName;
              return Chip(
                label: Text(p),
                backgroundColor: isThisPlayerHost
                    ? Colors.cyanAccent.withAlpha(100)
                    : Colors.white10,
                avatar: isThisPlayerHost
                    ? const Icon(Icons.star, size: 16, color: Colors.yellow)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 50),
          TextButton(
            onPressed: () {
              setState(() {
                _isWaiting = false;
                _isHost = false;
                _connectedPlayers.clear();
              });
              _gameService.stop();
            },
            child: const Text(
              "Batal / Keluar",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
