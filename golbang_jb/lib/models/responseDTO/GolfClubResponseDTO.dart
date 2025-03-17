import 'package:golbang/models/responseDTO/CourseResopnseDTO.dart';


class GolfClubResponseDTO {
  final int golfClubId;
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<CourseResponseDTO> courses ;

  GolfClubResponseDTO(this.golfClubId, this.golfClubName, this.address, this.longitude, this.latitude, this.courses);

  factory GolfClubResponseDTO.fromJson(Map<String, dynamic> json) {
    return GolfClubResponseDTO(
      json['golf_club_id'],
      json['golf_club_name'] ?? 'Unknown',
      json['address'] ?? 'Unknown',
      (json['longitude'] as num).toDouble(), // ✅ `num` 타입을 `double`로 변환
      (json['latitude'] as num).toDouble(),
      (json['courses'] as List) // ✅ JSON 배열을 리스트로 변환
          .map((course) => CourseResponseDTO.fromJson(course)) // ✅ 각 요소를 DTO로 변환
          .toList(),
    );
  }
  // ✅ 여러 개의 LocationResponseDTO를 변환하는 헬퍼 메서드 추가
  static List<GolfClubResponseDTO> fromJsonList(Map<String, dynamic> json) {
    return (json['data'] as List<dynamic>) // ✅ 'data' 키를 가져와 변환
        .map((item) => GolfClubResponseDTO.fromJson(item))
        .toList();
  }

}
