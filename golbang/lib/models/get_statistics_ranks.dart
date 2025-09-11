// GET  /clubs/statistics/ranks/?club_id={club_id} | 모임 내 랭킹 및 이벤트 리스트 랭킹 조회
class ClubStatistics {
  final ClubRanking ranking;
  final List<EventStatistics> events;

  ClubStatistics({required this.ranking, required this.events});

  factory ClubStatistics.fromJson(Map<String, dynamic> json) {
    return ClubStatistics(
      ranking: ClubRanking.fromJson(json['ranking']),
      events: (json['events'] as List)
          .map((eventJson) => EventStatistics.fromJson(eventJson))
          .toList(),
    );
  }
}

class ClubRanking {
  final int memberId;
  final String name;
  final String? profile;
  final String totalRank; // T1 같은 문자열을 그대로 처리
  final String totalHandicapRank; // T1 같은 문자열을 그대로 처리
  final int totalPoints;
  final int totalEvents;
  final int participationCount;
  final double participationRate;

  ClubRanking({
    required this.memberId,
    required this.name,
    this.profile,
    required this.totalRank,
    required this.totalHandicapRank,
    required this.totalPoints,
    required this.totalEvents,
    required this.participationCount,
    required this.participationRate,
  });

  factory ClubRanking.fromJson(Map<String, dynamic> json) {
    return ClubRanking(
      memberId: json['member_id'],
      name: json['name'],
      profile: json['profile'],
      totalRank: json['total_rank'], // 그대로 문자열로 처리
      totalHandicapRank: json['total_handicap_rank'], // 그대로 문자열로 처리
      totalPoints: json['total_points'],
      totalEvents: json['total_events'],
      participationCount: json['participation_count'],
      participationRate: json['participation_rate'].toDouble(),
    );
  }
}

class EventStatistics {
  final int eventId;
  final String eventName;
  final int sumScore;
  final int handicapScore;
  final int points;
  final int totalParticipants;
  final String rank; // TODO: rank가 int가 아닌 string으로 오는것으로 추정됨.
  final String handicapRank;

  EventStatistics({
    required this.eventId,
    required this.eventName,
    required this.sumScore,
    required this.handicapScore,
    required this.points,
    required this.totalParticipants,
    required this.rank,
    required this.handicapRank,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
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
