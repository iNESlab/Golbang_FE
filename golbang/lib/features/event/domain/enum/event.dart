enum GameMode {
  STROKE('SP');
  // MATCH_PLAY('MP');

  final String value;
  const GameMode(this.value);

  String toJson() => value;
}

enum TeamConfig {
  NONE('NONE'),
  TEAM_A('A'),
  TEAM_B('B');

  final String value;
  const TeamConfig(this.value);

  String toJson() => value;
}