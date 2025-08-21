// GET  /participants/statistics/overall/ | 전체 통계 조회 ✅


class OverallStatistics {
  final double averageScore;
  final int bestScore;
  final int handicapBestScore;
  final int gamesPlayed;

  OverallStatistics({
    required this.averageScore,
    required this.bestScore,
    required this.handicapBestScore,
    required this.gamesPlayed,
  });

  factory OverallStatistics.fromJson(Map<String, dynamic> json) {
    return OverallStatistics(
      averageScore: json['average_score'].toDouble(),
      bestScore: json['best_score'],
      handicapBestScore: json['handicap_bests_score'],
      gamesPlayed: json['games_played'],
    );
  }
}
