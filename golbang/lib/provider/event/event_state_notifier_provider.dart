import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/event/data/models/request/create_event_request_dto.dart';
import '../../features/event/data/models/create_participant_request_dto.dart';
import '../../models/event.dart';
import '../../features/event/data/datasources/event_remote_ds.dart';
import 'event_service_provider.dart';
import 'event_state_provider.dart';

// EventStateNotifierProvider 정의
final eventStateNotifierProvider = StateNotifierProvider<EventStateNotifierProvider, EventState>((ref) {
  final eventService = ref.read(eventServiceProvider);
  return EventStateNotifierProvider(eventService);
});

class EventStateNotifierProvider extends StateNotifier<EventState> {
  final EventService _eventService;

  EventStateNotifierProvider(this._eventService) : super(EventState());

  // 이벤트 목록을 불러오는 함수
  Future<void> fetchEvents({String? date, String? statusType}) async {
    state = state.copyWith(isLoading: true);
    try {
      final List<Event> events = await _eventService.getEventsForMonth(date: date, statusType: statusType);
      state = state.copyWith(eventList: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(errorMessage: '이벤트 목록을 불러오는 중 오류 발생', isLoading: false);
    }
  }

  // 이벤트 생성
  Future<bool> createEvent(CreateEvent event, List<CreateParticipant> participants, String clubId) async {
    try {
      final success = await _eventService.postEvent(clubId: int.parse(clubId), event: event, participants: participants);
      if (success) {
        await fetchEvents();
        return true;
      } else {
        state = state.copyWith(errorMessage: '이벤트 생성 실패');
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '이벤트 생성 중 오류 발생');
      return false;
    }
  }


  // 이벤트 수정
  Future<bool> updateEvent(CreateEvent updatedEvent, List<CreateParticipant> participants) async {
    try {
      final success = await _eventService.updateEvent(event: updatedEvent, participants: participants);
      if (success) {
        // 이벤트 수정 성공 시 전체 이벤트 목록을 다시 불러옴
        await fetchEvents();
        return true;
      } else {
        state = state.copyWith(errorMessage: '이벤트 수정 실패');
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '이벤트 수정 중 오류 발생');
      return false;
    }
  }

  // 이벤트 삭제
  Future<bool> deleteEvent(int eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      final success = await _eventService.deleteEvent(eventId);
      if (success) {
        // 이벤트 삭제 후 목록을 다시 불러와 업데이트
        await fetchEvents(); // 이벤트 삭제 후 새로고침
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(errorMessage: '이벤트 삭제 실패', isLoading: false);
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: '이벤트 삭제 중 오류 발생', isLoading: false);
      return false;
    }
  }

  // 상태 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
