import 'package:golbang/models/responseDTO/CourseResopnseDTO.dart';


class LocationResponseDTO {
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<CourseResponseDTO> courses ;

  LocationResponseDTO(this.golfClubName, this.address, this.longitude, this.latitude, this.courses);

  factory LocationResponseDTO.fromJson(Map<String, dynamic> json) {
    return LocationResponseDTO(
      json['golf_club_name'],
      json['address'],
      json['longitude'],
      json['latitude'],
      (json['courses'] as List) // ✅ JSON 배열을 리스트로 변환
          .map((course) => CourseResponseDTO.fromJson(course)) // ✅ 각 요소를 DTO로 변환
          .toList(),
    );
  }

}
