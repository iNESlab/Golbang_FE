// models/hole_score.py
// 홀 정보

class HoleScore {
  final int holeNumber;
  final int score;

  HoleScore({
    required this.holeNumber,
    required this.score,
  });

  factory HoleScore.fromJson(Map<String, dynamic> json) {
    return HoleScore(
      holeNumber: json['hole_number'],
      score: json['score'],
    );
  }
}