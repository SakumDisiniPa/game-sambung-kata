import '../../../services/update_service.dart';

class LobbyState {
  final List<String> connectedPlayers;
  final bool isWaiting;
  final bool isHost;
  final bool isMuted;
  final String myHostName;
  final String appVersion;
  final int highScore;
  final String savedName;
  final UpdateInfo? availableUpdate;

  LobbyState({
    this.connectedPlayers = const [],
    this.isWaiting = false,
    this.isHost = false,
    this.isMuted = false,
    this.myHostName = '',
    this.appVersion = '',
    this.highScore = 0,
    this.savedName = '',
    this.availableUpdate,
  });

  LobbyState copyWith({
    List<String>? connectedPlayers,
    bool? isWaiting,
    bool? isHost,
    bool? isMuted,
    String? myHostName,
    String? appVersion,
    int? highScore,
    String? savedName,
    UpdateInfo? availableUpdate,
  }) {
    return LobbyState(
      connectedPlayers: connectedPlayers ?? this.connectedPlayers,
      isWaiting: isWaiting ?? this.isWaiting,
      isHost: isHost ?? this.isHost,
      isMuted: isMuted ?? this.isMuted,
      myHostName: myHostName ?? this.myHostName,
      appVersion: appVersion ?? this.appVersion,
      highScore: highScore ?? this.highScore,
      savedName: savedName ?? this.savedName,
      availableUpdate: availableUpdate ?? this.availableUpdate,
    );
  }
}
