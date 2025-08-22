class CourseSummaryResponseDto {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;

  CourseSummaryResponseDto({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
  });

  factory CourseSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return CourseSummaryResponseDto(
      golfCourseId: json['golf_course_id'],
      golfCourseName: json['golf_course_name'] ?? 'Unknown',
      holes: json['holes'],
      par: json['par'],
    );
  }

}