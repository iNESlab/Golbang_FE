// 개인전 이벤트 결과 조회 Dto
import 'package:golbang/features/event/domain/enum/event_enum.dart';

class MyRecordDto {
  final String name;
  final String profileImage;
  final int stroke;
  final String rank;
  final String handicapRank;
  List<int?> scores;

  MyRecordDto({
    required this.name,
    required this.profileImage,
    required this.stroke,
    required this.rank,
    required this.handicapRank,
    required this.scores
  });

  factory MyRecordDto.fromJson(Map<String, dynamic> json) {
    return MyRecordDto(
      name: json['name'],
      profileImage: json['profile_image'] ?? '',
      stroke: json['stroke'] ?? 99,
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      scores: (json['scorecard'] as List<dynamic>?)
          ?.map((e) => e == null ? null : e as int)
          .toList()
          ?? <int?>[], // null-safe fallback
    );
  }
}

class IndividualRankResultDto {
  final int participantId;
  final String statusType;
  final String teamType;
  final int holeNumber;
  final int groupType;
  final int sumScore;
  final int handicapScore;
  final String rank;
  final String handicapRank;

  IndividualRankResultDto({
    required this.participantId,
    required this.statusType,
    required this.teamType,
    required this.holeNumber,
    required this.groupType,
    required this.sumScore,
    required this.handicapScore,
    required this.rank,
    required this.handicapRank
  });

  factory IndividualRankResultDto.fromJson(Map<String, dynamic> json) {
    return IndividualRankResultDto(
        participantId: json['participant_id'],
        statusType: json['status_type'],
        teamType: json['team_type'],
        holeNumber: json['hole_number'] ?? 99,
        groupType: json['group_type'],
        sumScore: json['sum_score'] ?? 99,
        handicapScore: json['handicap_score'] ?? 99,
        rank: json['rank'],
        handicapRank: json['handicap_rank']
    );
  }
}

class ReadEventIndividualResponseDto {
  final int eventId;
  final String eventTitle;
  final String site;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final GameMode gameMode;
  final MyRecordDto myRecordDto;
  final List<IndividualRankResultDto> individualRankResultDtos;

  ReadEventIndividualResponseDto({
    required this.eventId,
    required this.eventTitle,
    required this.site,
    required this.startDateTime,
    required this.endDateTime,
    required this.gameMode,
    required this.myRecordDto,
    required this.individualRankResultDtos
  });

  factory ReadEventIndividualResponseDto.fromJson(Map<String, dynamic> json) {
    List<dynamic> participants = json['participants'] as List<dynamic>;

    return ReadEventIndividualResponseDto(
        eventId: json['event_id'],
        eventTitle: json['event_title'],
        site: json['location'] ?? 'Unknown', //TODO: 서버에서 site로 수정해야함
        startDateTime: DateTime.parse(json['start_date_time']).toLocal(),
        endDateTime: DateTime.parse(json['end_date_time']).toLocal(),
        gameMode: GameModeX.fromString(json['game_mode'] as String),
        myRecordDto: MyRecordDto.fromJson(json['user']),
        individualRankResultDtos: participants.map((p) => IndividualRankResultDto.fromJson(p)).toList()
    );
  }

}