import 'package:golbang/features/event/data/models/golf_club/responses/course_detail_response_dto.dart';

class GolfClubDetailResponseDto {
  final int golfClubId;
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<CourseDetailResponseDto> courseDetailResponseDtos;

  GolfClubDetailResponseDto({
    required this.golfClubId,
    required this.golfClubName,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.courseDetailResponseDtos
  });

  factory GolfClubDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return GolfClubDetailResponseDto(
      golfClubId: json['golf_club_id'],
      golfClubName: json['golf_club_name'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      longitude: (json['longitude'] as num).toDouble(), // ✅ `num` 타입을 `double`로 변환
      latitude: (json['latitude'] as num).toDouble(),
      courseDetailResponseDtos: (json['courses'] as List?)
          ?.map((course) => CourseDetailResponseDto.fromJson(course))
          .toList() ?? [],
    );
  }

  factory GolfClubDetailResponseDto.fromClubAndCourseJson(
      Map<String, dynamic> golfClub,
      Map<String, dynamic> golfCourse,
    ) {
    return GolfClubDetailResponseDto(
      golfClubId: golfClub['golf_club_id'],
      golfClubName: golfClub['golf_club_name'] ?? 'Unknown',
      address: golfClub['address'] ?? 'Unknown',
      longitude: (golfClub['longitude'] as num).toDouble(),
      latitude: (golfClub['latitude'] as num).toDouble(),
      courseDetailResponseDtos: [CourseDetailResponseDto.fromJson(golfCourse)],
    );
  }

}
