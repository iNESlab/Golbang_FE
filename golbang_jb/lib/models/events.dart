// models/events.dart
// 이벤트
// 추후 이 코드를 event/user.dart에 덮어씌워야 함

import 'package:golbang/models/participant.dart';

class Events {
  final int id;
  final String title;
  final String location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String repeatType;
  final String gameMode;
  final DateTime? alertDateTime;
  final List<Participant> participants;

  Events({
    required this.id,
    required this.title,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.repeatType,
    required this.gameMode,
    this.alertDateTime,
    required this.participants,
  });

  factory Events.fromJson(Map<String, dynamic> json) {
    var participantsFromJson = json['participants'] as List;
    List<Participant> participantList = participantsFromJson.map((i) => Participant.fromJson(i)).toList();

    return Events(
      id: json['event_id'],
      title: json['event_title'],
      location: json['location'],
      startDateTime: DateTime.parse(json['start_date_time']),
      endDateTime: DateTime.parse(json['end_date_time']),
      repeatType: json['repeat_type'],
      gameMode: json['game_mode'],
      alertDateTime: json['alert_date_time'] != null ? DateTime.parse(json['alert_date_time']) : null,
      participants: participantList,
    );
  }
}
