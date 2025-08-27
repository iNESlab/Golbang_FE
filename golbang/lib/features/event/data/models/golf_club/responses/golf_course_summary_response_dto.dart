class GolfCourseSummaryResponseDto {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;

  GolfCourseSummaryResponseDto({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
  });

  factory GolfCourseSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return GolfCourseSummaryResponseDto(
      golfCourseId: json['golf_course_id'],
      golfCourseName: json['golf_course_name'] ?? 'Unknown',
      holes: json['holes'],
      par: json['par'],
    );
  }

}