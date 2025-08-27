import 'package:golbang/features/event/domain/enum/event_enum.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class Event {
  final int eventId;
  final String eventTitle;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String repeatType;
  final GameMode gameMode;

  Event({
    required this.eventId,
    required this.eventTitle,
    required this.startDateTime,
    required this.endDateTime,
    required this.repeatType,
    required this.gameMode
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.eventId == eventId;
  }

  @override
  int get hashCode => eventId.hashCode;

}

class DraftEventInput {
  final String eventTitle;
  final LatLng location;
  final String courseName;
  final int golfClubId;
  final int golfCourseId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String repeatType;
  final GameMode gameMode;
  final String alertDateTime;

  DraftEventInput({
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
  });
}