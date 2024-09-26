import '../../models/event.dart';

class EventState {
  final List<Event> eventList;
  final Event? selectedEvent;
  final bool isLoading;
  final String? errorMessage;

  EventState({
    this.eventList = const [],
    this.selectedEvent,
    this.isLoading = false,
    this.errorMessage,
  });

  EventState copyWith({
    List<Event>? eventList,
    Event? selectedEvent,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventState(
      eventList: eventList ?? this.eventList,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
