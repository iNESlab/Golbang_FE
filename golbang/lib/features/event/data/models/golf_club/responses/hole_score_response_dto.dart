// models/hole_score.py
// 홀 정보

class HoleScoreResponseDto {
  // final int holeId;
  final int holeNumber;
  final int score;

  HoleScoreResponseDto({
    // reuired this.holeId,
    required this.holeNumber,
    required this.score,
  });

  factory HoleScoreResponseDto.fromJson(Map<String, dynamic> json) {
    return HoleScoreResponseDto(
      // holeId: json['hole_id'] as int,
      holeNumber: json['hole_number'] as int,
      score: json['score'] as int,
    );
  }
}