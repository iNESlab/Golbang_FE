import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../participant/requests/create_participant_request_dto.dart';

class CreateEventRequestDto {
  final String eventTitle;
  final LatLng location;
  final String courseName;
  final int golfClubId;
  final int golfCourseId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String repeatType;
  final String gameMode;
  final String alertDateTime;
  final List<CreateParticipantRequestDto> createParticipantRequestDtos;

  CreateEventRequestDto({
    required this.eventTitle,
    required this.location,
    required this.courseName,
    required this.golfClubId,
    required this.golfCourseId,
    required this.startDateTime,
    required this.endDateTime,
    required this.repeatType,
    required this.gameMode,
    required this.alertDateTime,
    required this.createParticipantRequestDtos
  });

  Map<String, dynamic> toJson() {
    return {
      'event_title': eventTitle,
      'location': location.toString(),
      'course_name': courseName,
      'golf_club_id': golfClubId,
      'golf_course_id': golfCourseId,
      'start_date_time': startDateTime.toUtc().toIso8601String(),
      'end_date_time': endDateTime.toUtc().toIso8601String(),
      'repeat_type': repeatType,
      'game_mode': gameMode,
      'alert_date_time':'2024-07-31T09:00:00Z',//TODO: 임시 조치
      'participants': createParticipantRequestDtos,
    };
  }
}
