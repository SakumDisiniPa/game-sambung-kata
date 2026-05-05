import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/game_state.dart';
import '../../../services/sound_service.dart';
import '../providers/game_logic_provider.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/virtual_keyboard.dart';

class GameView extends ConsumerStatefulWidget {
  final String playerName;
  final bool isHost;
  const GameView({super.key, required this.playerName, this.isHost = false});

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView>
    with TickerProviderStateMixin {
  String _typedWord = "";
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Lock to portrait for mobile
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    Future.microtask(() {
      final notifier = ref.read(gameLogicProvider.notifier);
      if (!notifier.isDictionaryLoaded) {
        notifier.loadDictionary();
      }
    });
  }

  @override
  void dispose() {
    // Reset to all orientations when leaving game
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _focusNode.dispose();
    super.dispose();
  }

  void _addLetter(String letter) {
    setState(() {
      _typedWord += letter.toUpperCase();
    });
    ref.read(gameLogicProvider.notifier).updateTyping(_typedWord);
  }

  void _deleteLetter() {
    if (_typedWord.isNotEmpty) {
      setState(() {
        _typedWord = _typedWord.substring(0, _typedWord.length - 1);
      });
      ref.read(gameLogicProvider.notifier).updateTyping(_typedWord);
    }
  }

  void _submitWord(String prefix) {
    if (_typedWord.isEmpty) return;
    final word = prefix + _typedWord;
    ref.read(gameLogicProvider.notifier).submitWord(word, null);
    setState(() => _typedWord = "");
    ref.read(gameLogicProvider.notifier).updateTyping("");
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final gameState = ref.read(gameLogicProvider);
    if (gameState.isGameOver || gameState.isDictionaryLoading) {
      return KeyEventResult.ignored;
    }

    // Check apakah giliran kita
    if (gameState.players.isEmpty ||
        gameState.activePlayerIndex >= gameState.players.length) {
      return KeyEventResult.ignored;
    }
    final isMyTurn =
        gameState.players[gameState.activePlayerIndex] == widget.playerName;
    final isEliminated =
        gameState.eliminatedPlayers.contains(widget.playerName);
    if (!isMyTurn || isEliminated) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter) {
      _submitWord(gameState.currentPrefix);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.backspace) {
      _deleteLetter();
      return KeyEventResult.handled;
    } else {
      final char = event.character;
      if (char != null && RegExp(r'[a-zA-Z]').hasMatch(char)) {
        _addLetter(char);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameLogicProvider);

    // Reset typed word when prefix changes (giliran pindah)
    ref.listen(gameLogicProvider, (prev, next) {
      if (prev?.currentPrefix != next.currentPrefix ||
          prev?.activePlayerIndex != next.activePlayerIndex) {
        setState(() => _typedWord = "");
        // Auto focus if it's my turn (for physical keyboard)
        final isMyTurn = next.players.isNotEmpty &&
            next.activePlayerIndex < next.players.length &&
            next.players[next.activePlayerIndex] == widget.playerName;
        if (isMyTurn) {
          _focusNode.requestFocus();
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(
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
              Container(color: Colors.black.withAlpha(180)),

              // Glow effect
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyan.withAlpha(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.cyan.withAlpha(15), blurRadius: 100),
                    ],
                  ),
                ),
              ),

              if (gameState.isDictionaryLoading)
                const Center(child: LoadingStateWidget())
              else
                SafeArea(
                  child: Stack(
                    children: [
                      _buildGameContent(gameState),
                      
                      // Music Player di Tengah Atas
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildMusicPlayer(),
                        ),
                      ),
                    ],
                  ),
                ),

              // Game Over Overlay
              if (gameState.isGameOver) _buildGameOverOverlay(gameState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(GameState gameState) {
    final isMyTurn = gameState.players.isNotEmpty &&
        gameState.activePlayerIndex < gameState.players.length &&
        gameState.players[gameState.activePlayerIndex] == widget.playerName;
    final isEliminated =
        gameState.eliminatedPlayers.contains(widget.playerName);

    return Column(
      children: [
        const SizedBox(height: 20),

        // Player profiles di pojok kiri dan kanan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (gameState.players.isNotEmpty)
                _buildPlayerProfile(
                  gameState.players[0],
                  gameState.playerHealth[gameState.players[0]] ?? 4,
                  gameState.eliminatedPlayers.contains(gameState.players[0]),
                  gameState.players.isNotEmpty &&
                      gameState.activePlayerIndex < gameState.players.length &&
                      gameState.players[gameState.activePlayerIndex] ==
                          gameState.players[0],
                  gameState.playerScores[gameState.players[0]] ?? 0,
                ),
              if (gameState.players.length > 1)
                _buildPlayerProfile(
                  gameState.players[1],
                  gameState.playerHealth[gameState.players[1]] ?? 4,
                  gameState.eliminatedPlayers.contains(gameState.players[1]),
                  gameState.players.isNotEmpty &&
                      gameState.activePlayerIndex < gameState.players.length &&
                      gameState.players[gameState.activePlayerIndex] ==
                          gameState.players[1],
                  gameState.playerScores[gameState.players[1]] ?? 0,
                ),
            ],
          ),
        ),

        // Center content (Scrollable for mobile safety)
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // Giliran siapa
                if (gameState.players.isNotEmpty &&
                    gameState.activePlayerIndex < gameState.players.length)
                  Text(
                    isMyTurn
                        ? "GILIRAN KAMU!"
                        : "GILIRAN: ${gameState.players[gameState.activePlayerIndex]}",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: isMyTurn
                          ? Colors.cyanAccent
                          : Colors.white54,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 20),

                // Timer
                _buildTimer(gameState.timeLeft),

                const SizedBox(height: 40),

                // Word display (prefix + typed letters + empty boxes)
                _buildWordDisplay(
                    gameState.currentPrefix, isMyTurn && !isEliminated),

                const SizedBox(height: 30),

                // Kesempatan (turn chances)
                _buildChancesIndicator(gameState.turnChancesLeft),

                // Feedback (KATA SUDAH DIGUNAKAN, dll)
                if (gameState.lastFeedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      gameState.lastFeedback,
                      style: GoogleFonts.outfit(
                        color: gameState.lastFeedback == "BENAR!" 
                            ? Colors.greenAccent 
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                // Spectator mode
                if (isEliminated && !gameState.isGameOver)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withAlpha(100)),
                      ),
                      child: Text(
                        "KAMU TERELIMINASI 💀",
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Custom Virtual Keyboard
        if (isMyTurn && !isEliminated && !gameState.isGameOver)
          VirtualKeyboard(
            onKeyTap: _addLetter,
            onBackspace: _deleteLetter,
            onSubmit: () => _submitWord(gameState.currentPrefix),
          ),
      ],
    );
  }

  Widget _buildPlayerProfile(
      String name, int health, bool isEliminated, bool isActive, int score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.cyanAccent.withAlpha(25)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.cyanAccent.withAlpha(150)
              : (isEliminated
                  ? Colors.redAccent.withAlpha(80)
                  : Colors.white.withAlpha(20)),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: Colors.cyanAccent.withAlpha(30), blurRadius: 15),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.cyanAccent.withAlpha(40)
                  : Colors.white.withAlpha(15),
              border: Border.all(
                color: isActive ? Colors.cyanAccent : Colors.white24,
              ),
            ),
            child: Icon(
              Icons.person,
              color: isEliminated
                  ? Colors.white24
                  : (isActive ? Colors.cyanAccent : Colors.white70),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isEliminated ? Colors.white24 : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Health hearts
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              4,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < health ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: i < health
                      ? Colors.redAccent
                      : Colors.white.withAlpha(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withAlpha(isActive ? 40 : 15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$score PTS",
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isEliminated ? Colors.white24 : Colors.cyanAccent,
                letterSpacing: 1,
              ),
            ),
          ),
          // Eliminated label
          if (isEliminated)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "OUT",
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimer(int timeLeft) {
    final isUrgent = timeLeft <= 5;
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withAlpha(120),
            border: Border.all(
              color: isUrgent
                  ? Colors.redAccent.withAlpha(200)
                  : Colors.cyanAccent.withAlpha(100),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isUrgent
                    ? Colors.redAccent.withAlpha(40)
                    : Colors.cyanAccent.withAlpha(20),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              "$timeLeft",
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: isUrgent ? Colors.redAccent : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordDisplay(String prefix, bool isMyTurn) {
    // Pemain aktif: tampilkan dari local state (instant)
    // Pemain lawan: tampilkan dari synced state (via network)
    final gameState = ref.read(gameLogicProvider);
    final displayWord = isMyTurn ? _typedWord : gameState.currentTypedWord;
    final letters = displayWord.split('').where((l) => l.isNotEmpty).toList();
    final prefixLetters = prefix.split('');
    
    final feedback = gameState.lastFeedback;
    Color? statusColor;
    if (feedback == 'BENAR!') {
      statusColor = Colors.greenAccent;
    } else if (feedback.contains('VALID') || feedback.contains('DIGUNAKAN')) {
      statusColor = Colors.redAccent;
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 10,
      children: [
        // Prefix boxes (cyan)
        ...prefixLetters.map((l) => _buildLetterBox(l, isCyan: true)),
        
        // Separator if needed or just space
        const SizedBox(width: 4),

        // Typed letters
        ...letters.map((l) => _buildLetterBox(l, statusColor: statusColor)),

        // Cursor box (empty, only if my turn)
        if (isMyTurn && feedback.isEmpty)
          _buildLetterBox("", isCursor: true, statusColor: statusColor),
      ],
    );
  }

    Widget _buildMusicPlayer() {
    final sound = SoundService();
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withAlpha(50)),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withAlpha(10), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nama Lagu & Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 20, color: Colors.white70),
                onPressed: () async {
                  await sound.prevSong();
                  setState(() {});
                },
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      sound.currentSongName.replaceAll('.mp3', ''),
                      style: GoogleFonts.outfit(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Progress Bar
                    StreamBuilder<Duration>(
                      stream: sound.onPositionChanged,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? Duration.zero;
                        return StreamBuilder<Duration>(
                          stream: sound.onDurationChanged,
                          builder: (context, snapshotDur) {
                            final dur = snapshotDur.data ?? const Duration(seconds: 1);
                            double progress = pos.inMilliseconds / dur.inMilliseconds;
                            if (progress > 1.0) progress = 1.0;
                            return Container(
                              height: 2,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  sound.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await sound.togglePause();
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20, color: Colors.white70),
                onPressed: () async {
                  await sound.nextSong();
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLetterBox(String letter,
      {bool isCyan = false, bool isCursor = false, Color? statusColor}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 52,
      height: 60,
      decoration: BoxDecoration(
        color: statusColor != null 
            ? statusColor.withAlpha(40)
            : (isCyan
                ? Colors.cyanAccent.withAlpha(30)
                : (letter.isNotEmpty
                    ? Colors.white.withAlpha(15)
                    : Colors.white.withAlpha(6))),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor ?? (isCyan
              ? Colors.cyanAccent.withAlpha(180)
              : (isCursor
                  ? Colors.cyanAccent.withAlpha(80)
                  : Colors.white.withAlpha(30))),
          width: (isCyan || statusColor != null) ? 2 : 1.5,
        ),
        boxShadow: (isCyan || statusColor != null)
            ? [
                BoxShadow(
                    color: (statusColor ?? Colors.cyanAccent).withAlpha(20), 
                    blurRadius: 10),
              ]
            : [],
      ),
      child: Center(
        child: isCursor && letter.isEmpty
            ? Container(
                width: 2,
                height: 28,
                color: Colors.cyanAccent.withAlpha(120),
              )
            : Text(
                letter,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isCyan ? Colors.cyanAccent : Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildChancesIndicator(int chancesLeft) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "KESEMPATAN  ",
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white38,
            letterSpacing: 2,
          ),
        ),
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < chancesLeft
                    ? Colors.cyanAccent
                    : Colors.white.withAlpha(20),
                boxShadow: i < chancesLeft
                    ? [
                        BoxShadow(
                            color: Colors.cyanAccent.withAlpha(60),
                            blurRadius: 6),
                      ]
                    : [],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverOverlay(GameState gameState) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "GAME OVER",
              style: GoogleFonts.outfit(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "PEMENANG",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                letterSpacing: 3,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              gameState.winner ?? "No One",
              style: GoogleFonts.outfit(
                fontSize: 42,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                ref.read(gameLogicProvider.notifier).resetGame();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.home_rounded),
              label: Text(
                "KEMBALI KE LOBBY",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
