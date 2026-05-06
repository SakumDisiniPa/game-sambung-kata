import '../../../services/update_service.dart';

class LobbyState {
  final List<String> connectedPlayers;
  final bool isWaiting;
  final bool isHost;
  final bool isMuted;
  final String myHostName;
  final String appVersion;
  final int globalHighScore;
  final int personalHighScore;
  final List<Map<String, dynamic>> topPlayers;
  final String savedName;
  final String selectedLanguage;
  final UpdateInfo? availableUpdate;

  LobbyState({
    this.connectedPlayers = const [],
    this.isWaiting = false,
    this.isHost = false,
    this.isMuted = false,
    this.myHostName = '',
    this.appVersion = '',
    this.globalHighScore = 0,
    this.personalHighScore = 0,
    this.topPlayers = const [],
    this.savedName = '',
    this.selectedLanguage = 'indonesia',
    this.availableUpdate,
  });

  LobbyState copyWith({
    List<String>? connectedPlayers,
    bool? isWaiting,
    bool? isHost,
    bool? isMuted,
    String? myHostName,
    String? appVersion,
    int? globalHighScore,
    int? personalHighScore,
    List<Map<String, dynamic>>? topPlayers,
    String? savedName,
    String? selectedLanguage,
    UpdateInfo? availableUpdate,
  }) {
    return LobbyState(
      connectedPlayers: connectedPlayers ?? this.connectedPlayers,
      isWaiting: isWaiting ?? this.isWaiting,
      isHost: isHost ?? this.isHost,
      isMuted: isMuted ?? this.isMuted,
      myHostName: myHostName ?? this.myHostName,
      appVersion: appVersion ?? this.appVersion,
      globalHighScore: globalHighScore ?? this.globalHighScore,
      personalHighScore: personalHighScore ?? this.personalHighScore,
      topPlayers: topPlayers ?? this.topPlayers,
      savedName: savedName ?? this.savedName,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      availableUpdate: availableUpdate ?? this.availableUpdate,
    );
  }
}
