class Event {
  final String title;
  final String group;
  final String time;
  final String location;
  final int participants;
  final String organizer;
  final String paymentStatus;
  final String attendanceStatus;
  final bool isCompleted;

  Event(
      this.title,
      this.group,
      this.time,
      this.location,
      this.participants,
      this.organizer,
      this.paymentStatus,
      this.attendanceStatus,
      this.isCompleted,
      );

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      json['title'],
      json['group'],
      json['time'],
      json['location'],
      json['participants'],
      json['organizer'],
      json['paymentStatus'],
      json['attendanceStatus'],
      json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'group': group,
      'time': time,
      'location': location,
      'participants': participants,
      'organizer': organizer,
      'paymentStatus': paymentStatus,
      'attendanceStatus': attendanceStatus,
      'isCompleted': isCompleted,
    };
  }
}
