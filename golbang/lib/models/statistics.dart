// models/statistics.dart
// 개인통계 (전체, 연도별, 기간별)

class Statistics {
  final double averageScore;
  final int bestScore;
  final int handicapBestScore;
  final int gamesPlayed;

  Statistics({
    required this.averageScore,
    required this.bestScore,
    required this.handicapBestScore,
    required this.gamesPlayed,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      averageScore: json['average_score'],
      bestScore: json['best_score'],
      handicapBestScore: json['handicap_bests_score'],
      gamesPlayed: json['games_played'],
    );
  }
}
