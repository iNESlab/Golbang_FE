// 개인전 이벤트 결과 조회 Dto
import 'package:golbang/features/event/domain/enum/event_enum.dart';

class MyRecord {
  final String name;
  final String profileImage;
  final int stroke;
  final String rank;
  final String handicapRank;
  List<int?> scores;

  MyRecord({
    required this.name,
    required this.profileImage,
    required this.stroke,
    required this.rank,
    required this.handicapRank,
    required this.scores
  });
}

class IndividualRankResult {
  final int participantId;
  final String statusType;
  final String teamType;
  final int holeNumber;
  final int groupType;
  final int sumScore;
  final int handicapScore;
  final String rank;
  final String handicapRank;

  IndividualRankResult({
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
}

class EventIndividualResult {
  final int eventId;
  final String eventTitle;
  final String site;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final GameMode gameMode;
  final MyRecord myRecord;
  final List<IndividualRankResult> individualRankResults;

  EventIndividualResult({
    required this.eventId,
    required this.eventTitle,
    required this.site,
    required this.startDateTime,
    required this.endDateTime,
    required this.gameMode,
    required this.myRecord,
    required this.individualRankResults
  });

}