import 'dart:collection';
import 'package:table_calendar/table_calendar.dart';

import '../../models/event.dart';
import '../../utils/date_utils.dart'; // isSameDay, getHashCode 정의돼 있는 곳

class EventState {
  final LinkedHashMap<DateTime, List<Event>> eventsByDay;
  final Event? selectedEvent;
  final bool isLoading;

  EventState({
    LinkedHashMap<DateTime, List<Event>>? eventsByDay,
    this.selectedEvent,
    this.isLoading = false,
  }) : eventsByDay = eventsByDay ??
      LinkedHashMap<DateTime, List<Event>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );

  EventState copyWith({
    LinkedHashMap<DateTime, List<Event>>? eventsByDay,
    Event? selectedEvent,
    bool? isLoading,
  }) {
    return EventState(
      eventsByDay: eventsByDay ?? this.eventsByDay,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}