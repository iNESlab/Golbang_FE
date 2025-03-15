class CourseResponseDTO {
  final String golfCourseName;
  final String holes;
  final String par;

  CourseResponseDTO(this.golfCourseName, this.holes, this.par);

  factory CourseResponseDTO.fromJson(Map<String, dynamic> json) {
    return CourseResponseDTO(
      json['golf_course_name'],
      json['holes'],
      json['par'],
    );
  }
  // 서버로부터 응답받은 것이므로 toJson은 필요없음.
}
