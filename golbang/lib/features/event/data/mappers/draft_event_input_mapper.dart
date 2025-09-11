import 'package:golbang/features/event/data/models/event/requests/create_event_request_dto.dart';
import 'package:golbang/features/event/data/models/participant/requests/create_participant_request_dto.dart';

import '../../domain/entities/event.dart';
import '../models/event/requests/update_event_request_dto.dart';
import '../models/participant/requests/update_participant_request_dto.dart';


extension DraftEventInputMapper on DraftEventInput {
  CreateEventRequestDto toCreateEventReqDto({
    required List<CreateParticipantRequestDto> createParticipantRequestDtos
  }) => CreateEventRequestDto(
    eventTitle: eventTitle,
    location: location,
    courseName: courseName,
    golfClubId: golfClubId,
    golfCourseId: golfCourseId,
    startDateTime: startDateTime,
    endDateTime: endDateTime,
    repeatType: repeatType,
    gameMode: gameMode,
    alertDateTime: alertDateTime,
    createParticipantRequestDtos: createParticipantRequestDtos
  );

  UpdateEventRequestDto toUpdateEventReqDto({
    required List<UpdateParticipantRequestDto> updateParticipantRequestDtos
  }) => UpdateEventRequestDto(
      eventTitle: eventTitle,
      location: location,
      courseName: courseName,
      golfClubId: golfClubId,
      golfCourseId: golfCourseId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      repeatType: repeatType,
      gameMode: gameMode,
      alertDateTime: alertDateTime,
      updateParticipantRequestDtos: updateParticipantRequestDtos
  );
}