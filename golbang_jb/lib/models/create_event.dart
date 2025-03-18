// event.dart
class CreateEvent {
  final int? eventId;
  final String? memberGroup;
  final String eventTitle;
  final String? location;
  final String site;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? repeatType;
  final String? gameMode;
  final String? alertDateTime;

  CreateEvent({
    this.eventId,
    this.memberGroup,
    required this.eventTitle,
    this.location,
    required this.site,
    required this.startDateTime,
    required this.endDateTime,
    this.repeatType,
    this.gameMode,
    this.alertDateTime,
  });

  factory CreateEvent.fromJson(Map<String, dynamic> json) {

    return CreateEvent(
      eventId: json['event_id'],
      memberGroup: json['memberGroup'] ?? "",
      eventTitle: json['event_title'],
      location: json['location'],
      site: json['site'],
      startDateTime: DateTime.parse(json['start_date_time']),
      endDateTime: DateTime.parse(json['end_date_time']),
      repeatType: json['repeat_type'] ?? "",
      gameMode: json['game_mode'],
      alertDateTime: json['alert_date_time'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_title': eventTitle,
      'location': location,
      'site': site,
      'start_date_time': startDateTime.toUtc().toIso8601String(),
      'end_date_time': endDateTime.toUtc().toIso8601String(),
      'repeat_type': repeatType,
      'game_mode': gameMode,
      'alert_date_time':'2024-07-31T09:00:00Z',//TODO: 임시 조치
    };
  }
}
