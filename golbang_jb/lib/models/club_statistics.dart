// models/club_statistics.dart
// 모임별 랭킹

class ClubStatistics {
  final int clubId;
  final int totalRank;
  final int totalHandicapRank;
  final int totalPoints;
  final int totalEvents;
  final int participationCount;
  final double participationRate;
  final List<EventRanking> events;

  ClubStatistics({
    required this.clubId,
    required this.totalRank,
    required this.totalHandicapRank,
    required this.totalPoints,
    required this.totalEvents,
    required this.participationCount,
    required this.participationRate,
    required this.events,
  });

  factory ClubStatistics.fromJson(Map<String, dynamic> json) {
    var eventsFromJson = json['events'] as List;
    List<EventRanking> eventList = eventsFromJson.map((i) => EventRanking.fromJson(i)).toList();

    return ClubStatistics(
      clubId: json['club_id'],
      totalRank: json['total_rank'],
      totalHandicapRank: json['total_handicap_rank'],
      totalPoints: json['total_points'],
      totalEvents: json['total_events'],
      participationCount: json['participation_count'],
      participationRate: json['participation_rate'],
      events: eventList,
    );
  }
}

class EventRanking {
  final int eventId;
  final String eventName;
  final int sumScore;
  final int handicapScore;
  final int points;
  final int totalParticipants;
  final int rank;
  final int handicapRank;

  EventRanking({
    required this.eventId,
    required this.eventName,
    required this.sumScore,
    required this.handicapScore,
    required this.points,
    required this.totalParticipants,
    required this.rank,
    required this.handicapRank,
  });

  factory EventRanking.fromJson(Map<String, dynamic> json) {
    return EventRanking(
      eventId: json['event_id'],
      eventName: json['event_name'],
      sumScore: json['sum_score'],
      handicapScore: json['handicap_score'],
      points: json['points'],
      totalParticipants: json['total_participants'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
    );
  }
}
