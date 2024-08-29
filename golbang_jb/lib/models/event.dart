// event.dart

import 'package:golbang/models/participant.dart';

class Event {
  final int eventId;
  final String? memberGroup;
  final String eventTitle;
  final String? location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? repeatType;
  final String? gameMode;
  final String? alertDateTime;
  final int participantsCount;
  final int partyCount;
  final int acceptCount;
  final int denyCount;
  final int pendingCount;
  final int myParticipantId;
  final List<Participant> participants;

  Event({
    required this.eventId,
    this.memberGroup,
    required this.eventTitle,
    this.location,
    required this.startDateTime,
    required this.endDateTime,
    this.repeatType,
    this.gameMode,
    this.alertDateTime,
    required this.participantsCount,
    required this.partyCount,
    required this.acceptCount,
    required this.denyCount,
    required this.pendingCount,
    required this.myParticipantId,
    required this.participants,
  });

  factory Event.fromJson(Map<String, dynamic> json) {

    print(json['group']);
    print("PASSS");
    return Event(
      eventId: json['event_id'],
      memberGroup: json['memberGroup'] ?? "",
      eventTitle: json['event_title'],
      location: json['location'],
      startDateTime: DateTime.parse(json['start_date_time']),
      endDateTime: DateTime.parse(json['end_date_time']),
      repeatType: json['repeat_type'] ?? "",
      gameMode: json['game_mode'],
      alertDateTime: json['alert_date_time'] ?? "",
      participantsCount: json['participants_count'],
      partyCount: json['party_count'],
      acceptCount: json['accept_count'],
      denyCount: json['deny_count'],
      pendingCount: json['pending_count'],
      myParticipantId: json['my_participant_id'],
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
    );
  }
}
