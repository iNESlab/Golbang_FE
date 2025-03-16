class CourseResponseDTO {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;
  final List<int> holePars;
  final List<int> holeHandicaps;

  CourseResponseDTO({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
    required this.holePars,
    required this.holeHandicaps,
  });

  factory CourseResponseDTO.fromJson(Map<String, dynamic> json) {
    return CourseResponseDTO(
      golfCourseId: json['golf_course_id'],
      golfCourseName: json['golf_course_name'],
      holes: json['holes'],
      par: json['par'],
      holePars: List<int>.from(json['hole_pars'] ?? []),
      holeHandicaps: List<int>.from(json['hole_handicaps'] ?? []),
    );
  }
  // 서버로부터 응답받은 것이므로 toJson은 필요없음.
}
