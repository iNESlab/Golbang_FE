import 'package:golbang/features/event/data/models/golf_club/responses/golf_club_detail_response_dto.dart';
import 'package:golbang/features/event/data/models/participant/responses/participant_summary_response_dto.dart';

class ClubProfileDto{
  final int clubId;
  final String clubName;
  final String clubImage;

  ClubProfileDto({
    required this.clubId,
    required this.clubName,
    required this.clubImage,
  });

  factory ClubProfileDto.fromJson(Map<String, dynamic> json) {
    int groupId = json['id'] ?? 0;
    String defaultImage = 'assets/images/golbang_group_${groupId % 7}.webp';
    return ClubProfileDto(
        clubId: json['id'],
        clubName: json['name'],
        clubImage: json['image']??defaultImage
    );
  }
}

class ReadEventDetailResponseDto {
  final ClubProfileDto club; // ㅇ
  final int eventId; // ㅇ
  final int memberGroup; // ㅇ
  final String eventTitle; // ㅇ
  final String location; // ㅇ
  final String site; // ㅇ
  final DateTime startDateTime; // ㅇ
  final DateTime endDateTime; // ㅇ
  final String repeatType; // ㅇ
  final String gameMode; // ㅇ
  // final String alertDateTime; // ㅇ
  final int participantsCount; // ㅇ
  final int partyCount; // ㅇ
  final int acceptCount; // ㅇ
  final int denyCount; // ㅇ
  final int pendingCount; // ㅇ
  final int myParticipantId; // ㅇ
  final List<ParticipantSummaryResponseDto> participantSummaryResponseDtos;
  final GolfClubDetailResponseDto golfClubDetailResponseDto;

  ReadEventDetailResponseDto({
    required this.club,
    required this.eventId,
    required this.memberGroup,
    required this.eventTitle,
    required this.location,
    required this.site,
    required this.startDateTime,
    required this.endDateTime,
    required this.repeatType,
    required this.gameMode,
    // required this.alertDateTime,
    required this.participantsCount,
    required this.partyCount,
    required this.acceptCount,
    required this.denyCount,
    required this.pendingCount,
    required this.myParticipantId,
    required this.participantSummaryResponseDtos,
    required this.golfClubDetailResponseDto,
  });

  factory ReadEventDetailResponseDto.fromJson(Map<String, dynamic> json) {
    return ReadEventDetailResponseDto(
      club: json['club'],
      eventId: json['event_id'],
      memberGroup: json['member_group'],
      eventTitle: json['event_title'],
      location: json['location'],
      site: json['site'],
      startDateTime: json['start_date_time'],
      endDateTime: json['end_date_time'],
      repeatType: json['repeat_type'],
      gameMode: json['game_mode'],
      participantsCount: json['participants_count'],
      partyCount: json['party_count'],
      acceptCount: json['accept_count'],
      denyCount: json['deny_count'],
      pendingCount: json['pending_count'],
      myParticipantId: json['my_participant_id'],
      participantSummaryResponseDtos: (json['participants'] as List<dynamic>)
          .map((p) => ParticipantSummaryResponseDto.fromJson(p))
          .toList(),
      golfClubDetailResponseDto: GolfClubDetailResponseDto.fromClubAndCourseJson(json['golf_club'], json['golf_course']), //TODO: 지금 서버 API는 course랑 분리해서 주는데 통합하는걸로 조치해야함
    );
  }
}