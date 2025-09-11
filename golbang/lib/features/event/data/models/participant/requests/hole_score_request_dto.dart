class HoleScoreRequestDto {
  final int holeNumber;
  final int? score; // null일 경우, 해당 hole 점수 삭제

  HoleScoreRequestDto({
    // reuired this.holeId,
    required this.holeNumber,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'holeNumber': holeNumber,
      'score': score
    };
  }
}