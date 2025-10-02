import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/create_event.dart';
import '../../models/create_participant.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/participant_service.dart';
import '../../utils/date_utils.dart';
import 'event_service_provider.dart';
import 'event_state_provider.dart';

// EventStateNotifierProvider 정의
final eventStateNotifierProvider = StateNotifierProvider<EventStateNotifierProvider, EventState>((ref) {
  final eventService = ref.read(eventServiceProvider);
  final participantService = ref.read(participantServiceProvider);

  return EventStateNotifierProvider(eventService, participantService);
});

class EventStateNotifierProvider extends StateNotifier<EventState> {
  final EventService _eventService;
  final ParticipantService _participantService;

  EventStateNotifierProvider(this._eventService, this._participantService) : super(EventState());

  // 이벤트 목록을 불러오는 함수
  Future<void> fetchEvents({String? date, String? statusType}) async {
    state = state.copyWith(isLoading: true);
    final events = await _eventService.getEventsForMonth(date: date, statusType: statusType);

      // 날짜별로 그룹핑
      final byDay = LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );
      for (var e in events) {
        final day = DateTime(e.startDateTime.year, e.startDateTime.month, e.startDateTime.day);
        (byDay[day] ??= []).add(e);
      }

      // 각 날짜별 이벤트 정렬
      byDay.forEach((day, list) {
        list.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
      });

      state = state.copyWith(
        eventsByDay: byDay,
        isLoading: false,
      );
  }

  /// 이벤트 생성
  Future<void> createEvent(CreateEvent event, List<CreateParticipant> participants, String clubId) async {
      await _eventService.postEvent(
        clubId: int.parse(clubId),
        event: event,
        participants: participants,
      );

      await fetchEvents(); //TODO: postEvent 응답을 list조회 응답과 맞춰서 API 재호출 없이 상태관리할 수 있게 바꿔야함
  }


  // 이벤트 수정
  Future<void> updateEvent(CreateEvent updatedEvent, List<CreateParticipant> participants) async {
    await _eventService.updateEvent(event: updatedEvent, participants: participants);
    await fetchEvents();
  }

  // 이벤트 삭제
  Future<void> deleteEvent(int eventId) async {
    await _eventService.deleteEvent(eventId);
    await fetchEvents();
  }

  Future<void> updateParticipantStatus(int eventId, int participantId, String newStatus) async {
    await _participantService.updateParticipantStatus(participantId, newStatus);

    // 기존 맵 복사할 때도 equals/hashCode 유지
    final byDay = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(state.eventsByDay);

    // 특정 이벤트 찾아서 업데이트
    byDay.forEach((day, events) {
      for (final e in events) {
        if (e.eventId == eventId) {
          final participant = e.participants.firstWhere(
                (p) => p.participantId == participantId,
          );
          participant.statusType = newStatus;
        }
      }
    });

    state = state.copyWith(eventsByDay: byDay);
  }

  // 상태 초기화
  void clearLoading() {
    state = state.copyWith(isLoading: false);
  }
}
