import 'dart:collection';

import 'package:collection/collection.dart';
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

  Event? getEventFromState(int eventId) {
    return state.eventsByDay.values.expand((list) => list)
        .firstWhereOrNull((e) => e.eventId == eventId,);
  }

  // EventStateNotifier
  Future<Event> fetchEventDetails(int eventId) async {
    final event = await _eventService.getEventDetails(eventId) as Event;
    // state.eventsByDay에 반영 (딥링크 케이스도 포함)
    final byDay = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )
      ..addAll(state.eventsByDay);

    final dayKey = DateTime(event.startDateTime.year, event.startDateTime.month,
        event.startDateTime.day);
    final events = byDay[dayKey] ?? [];
    final idx = events.indexWhere((e) => e.eventId == event.eventId);

    if (idx >= 0) {
      events[idx] = event; // 갱신
    } else {
      events.add(event); // 없으면 추가
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    }

    byDay[dayKey] = events;
    state = state.copyWith(eventsByDay: byDay);
    return event;
  }

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

  Future<void> endEvent(Event event) async {
    await _eventService.endEvent(event.eventId);

    final byDay = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(state.eventsByDay);

    final startDateTime = event.startDateTime;
    final dayKey = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
    final events = byDay[dayKey];

    if (events != null) {
      final idx = events.indexWhere((e) => e.eventId == event.eventId);
      if (idx != -1) {
        final oldEvent = events[idx];
        final updatedEvent = oldEvent.copyWith(
          endDateTime: DateTime.now(), // ✅ 여기서 갱신
        );

        events[idx] = updatedEvent; // 리스트에 교체
      } else {
        throw Exception("eventId ${event.eventId} not found in day $dayKey");
      }
    }

    state = state.copyWith(eventsByDay: byDay);
  }

  // 상태 초기화
  void clearLoading() {
    state = state.copyWith(isLoading: false);
  }
}
