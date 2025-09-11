import 'package:golbang/features/event/domain/enum/event_enum.dart';

import 'hole_score.dart';

class ParticipantRecord {
  final int participantId;
  final String memberName;
  final int groupType;
  final TeamConfig teamType;
  // final bool isGroupWin;
  // final bool isGroupWinHandicap;
  final int sumScore; // nullable로 변경
  final int handicapScore; //TODO: nullable인지 확인해야함
  final List<HoleScore>? holeScores;

  ParticipantRecord({
    required this.participantId,
    required this.memberName,
    required this.groupType,
    required this.teamType,
    required this.sumScore,
    required this.handicapScore,
    required this.holeScores
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParticipantRecord && other.participantId == participantId;
  }

  @override
  int get hashCode => participantId.hashCode;

}