// GET  /participants/statistics/yearly/{year} | 연도별 통계 조회 ✅

class YearStatistics {
  final String year;
  final double averageScore;
  final int bestScore;
  final int handicapBestScore;
  final int gamesPlayed;

  YearStatistics({
    required this.year,
    required this.averageScore,
    required this.bestScore,
    required this.handicapBestScore,
    required this.gamesPlayed,
  });

  factory YearStatistics.fromJson(Map<String, dynamic> json) {
    return YearStatistics(
      year: json['year'],
      averageScore: json['average_score'].toDouble(),
      bestScore: json['best_score'],
      handicapBestScore: json['handicap_bests_score'],
      gamesPlayed: json['games_played'],
    );
  }
}
