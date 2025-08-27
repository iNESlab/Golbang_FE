import 'package:golbang/features/event/domain/enum/event_enum.dart';

class ParticipantScores {
  // final int participantId;
  final TeamConfig teamType;
  final int frontNineScore;
  final int backNineScore;
  final int? totalScore;
  final int? handicapScore;
  final List<int?> scores;

  ParticipantScores({
    required this.teamType,
    required this.frontNineScore,
    required this.backNineScore,
    required this.totalScore,
    required this.handicapScore,
    required this.scores
  });

}