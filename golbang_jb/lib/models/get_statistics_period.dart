class PeriodStatistics {
  final String startDate;
  final String endDate;
  final double averageScore;
  final int bestScore;
  final int gamesPlayed;

  PeriodStatistics({
    required this.startDate,
    required this.endDate,
    required this.averageScore,
    required this.bestScore,
    required this.gamesPlayed,
  });

  factory PeriodStatistics.fromJson(Map<String, dynamic> json) {
    return PeriodStatistics(
      startDate: json['start_date'],
      endDate: json['end_date'],
      averageScore: json['average_score'].toDouble(),
      bestScore: json['best_score'],
      gamesPlayed: json['games_played'],
    );
  }
}
