// event.dart

import 'package:golbang/models/participant.dart';
import 'package:golbang/models/profile/club_profile.dart';
import 'package:golbang/models/update_event_participant.dart';

class Event {
  final ClubProfile? club;
  final int eventId;
  final int memberGroup;
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
    this.club,
    required this.eventId,
    required this.memberGroup,
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

    return Event(
      club: json['club'] != null ? ClubProfile.fromJson(json['club']) : null,
      eventId: json['event_id'],
      memberGroup: json['member_group'],
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

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'memberGroup': memberGroup,
      'event_title': eventTitle,
      'location': location,
      'start_date_time': startDateTime.toIso8601String(),
      'end_date_time': endDateTime.toIso8601String(),
      'repeat_type': repeatType,
      'game_mode': gameMode,
      'alert_date_time': alertDateTime,
      'my_participant_id': myParticipantId,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }

  // UpdateEventParticipant로 변환하는 코드
  List<UpdateEventParticipant> toUpdateEventParticipantList() {
    return participants.map((participant) {
      return UpdateEventParticipant(
        memberId: participant.member?.memberId ?? 0,
        name: participant.member?.name ?? 'Unknown',
        profileImage: participant.member?.profileImage ?? 'assets/images/user_default.png',
        role: participant.member?.role ?? 'member',
        participantId: participant.participantId,
        statusType: participant.statusType,
        teamType: participant.teamType,
        holeNumber: participant.holeNumber,
        groupType: participant.groupType,
        sumScore: participant.sumScore,
        rank: participant.rank,
        handicapRank: participant.handicapRank,
        handicapScore: participant.handicapScore,
      );
    }).toList();
  }

}
