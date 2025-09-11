enum GameMode {
  stroke('SP');
  // MATCH_PLAY('MP');

  final String value;
  const GameMode(this.value);

  String toJson() => value;
}

enum TeamConfig {
  none('NONE'),
  teamA('A'),
  teamB('B');

  final String value;
  const TeamConfig(this.value);

  String toJson() => value;
}

extension GameModeX on GameMode {
  static GameMode fromString(String value) {
    switch (value) {
      case 'STROKE': return GameMode.stroke;
      // case 'MATCH': return GameMode.match;
      // case 'SCRAMBLE': return GameMode.scramble;
      default: throw ArgumentError('Unknown GameMode: $value');
    }
  }
}

extension TeamConfigX on TeamConfig {
  static TeamConfig fromString(String value) {
    switch (value) {
      case 'NONE': return TeamConfig.none;
      case 'A': return TeamConfig.teamA;
      case 'B': return TeamConfig.teamB;
      default: return TeamConfig.none;
    }
  }
}