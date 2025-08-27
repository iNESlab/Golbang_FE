import 'golf_course_summary_response_dto.dart';


class GolfClubSummaryResponseDto {
  final int golfClubId;
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<GolfCourseSummaryResponseDto> golfCourseSummaryResponseDtos;

  GolfClubSummaryResponseDto({
    required this.golfClubId,
    required this.golfClubName,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.golfCourseSummaryResponseDtos
  });

  factory GolfClubSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    return GolfClubSummaryResponseDto(
      golfClubId: json['golf_club_id'],
      golfClubName: json['golf_club_name'] ?? 'Unknown',
      address: json['address'] ?? 'Unknown',
      longitude: (json['longitude'] as num).toDouble(), // ✅ `num` 타입을 `double`로 변환
      latitude: (json['latitude'] as num).toDouble(),
      golfCourseSummaryResponseDtos: (json['courses'] as List?)
          ?.map((course) => GolfCourseSummaryResponseDto.fromJson(course))
          .toList() ?? [],
    );
  }
  // ✅ 여러 개의 LocationResponseDTO를 변환하는 헬퍼 메서드 추가
  static List<GolfClubSummaryResponseDto>? fromJsonList(Map<String, dynamic> json) {
    return (json['data'] as List<dynamic>?)
        ?.map((item) => GolfClubSummaryResponseDto.fromJson(item))
        .toList() ?? [];
  }

}
