// models/hole_score.py
// 홀 정보

class HoleScore {
  final int? holeNumber;
  final int? score;

  HoleScore({
    this.holeNumber,
    this.score,
  });

  factory HoleScore.fromJson(Map<String, dynamic> json) {
    return HoleScore(
      holeNumber: json['hole_number'] as int?,
      score: json['score'] as int?,
    );
  }
}