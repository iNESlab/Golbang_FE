class GolfCourseDetailResponseDto {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;
  final List<TeeResponseDto> teeDtos;

  GolfCourseDetailResponseDto({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
    required this.teeDtos,
  });

  factory GolfCourseDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return GolfCourseDetailResponseDto(
      golfCourseId: json['golf_course_id'] ?? -1,
      golfCourseName: json['golf_course_name'] ?? 'Unknown',
      holes: json['holes'],
      par: json['par'],
      teeDtos: (json['tees'] != null && json['tees'] is List) // null 체크 및 타입 확인
          ? (json['tees'] as List)
          .map((tee) => TeeResponseDto.fromJson(tee))
          .toList()
          : [], // null이면 빈 리스트 반환
    );
  }
  // 서버로부터 응답받은 것이므로 toJson은 필요없음.
}

class TeeResponseDto {
  // final int teeId; TODO: 서버에서 응답해야함
  final String teeName;
  final List<String> holePars;
  final List<String> holeHandicaps;

  TeeResponseDto({
    // required this.teeId,
    required this.teeName,
    required this.holePars,
    required this.holeHandicaps,
  });

  factory TeeResponseDto.fromJson(Map<String, dynamic> json) {
    return TeeResponseDto(
      // teeId: json['tee_id'],
      teeName: json['tee_name'] ?? "Blue",
      holePars: List<String>.from(json['hole_pars'] ?? []),
      holeHandicaps: List<String>.from(json['hole_handicaps'] ?? []),
    );
  }
}