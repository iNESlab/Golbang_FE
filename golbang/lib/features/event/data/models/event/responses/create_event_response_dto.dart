import 'package:golbang/features/event/domain/enum/event.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PostEventResponseDto {
  final int eventId;
  final String eventTitle;
  final LatLng location;
  final String site;
  final int golfClubId;
  final int golfCourseId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String repeatType;
  final GameMode gameMode;
  // final List<ParticipantProfileDto> participantProfileDto;
  // final DateTime alertDateTime;

  PostEventResponseDto({
    required this.eventId,
    required this.eventTitle,
    required this.location,
    required this.site,
    required this.golfClubId,
    required this.golfCourseId,
    required this.startDateTime,
    required this.endDateTime,
    required this.repeatType,
    required this.gameMode
  });

  factory PostEventResponseDto.fromJson(Map<String, dynamic> json){
    final locationStr = json['location'] as String;
    final cleaned = locationStr
        .replaceAll('LatLng(', '')
        .replaceAll(')', '')
        .split(',');

    final latitude = double.parse(cleaned[0].trim());
    final longitude = double.parse(cleaned[1].trim());

    return PostEventResponseDto(
      eventId: json['event_id'], //TODO: club_member_id로 서버에서 수정해야함
      eventTitle: json['event_title'], //TODO: is_current_user_admin => is_club_admin으로 서버 수정해야함
      location: LatLng(latitude, longitude), // TODO: 스프링에서 member로 그리고, id가 아닌 member_id로 응답해야함
      site: json['site'],
      golfClubId: json['golf_club_id'],
      golfCourseId: json['golf_course_id'],
      startDateTime: json['start_date_time'],
      endDateTime: json['end_date_time'],
      repeatType: json['repeat_type'],
      gameMode: json['game_mode'],
    );
  }
}