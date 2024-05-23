class Event {
  final String eventName;
  final String groupName;
  final String time;
  final String location;
  final int numberOfPeople;
  final String groupFormation;
  final String yardage;
  final String dinnerStatus;
  final bool isAdmin;

  Event(
      this.eventName,
      this.groupName,
      this.time,
      this.location,
      this.numberOfPeople,
      this.groupFormation,
      this.yardage,
      this.dinnerStatus,
      this.isAdmin);

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      json['eventName'],
      json['groupName'],
      json['time'],
      json['location'],
      json['numberOfPeople'],
      json['groupFormation'],
      json['yardage'],
      json['dinnerStatus'],
      json['isAdmin'],
    );
  }

  int get attending => numberOfPeople;
  int get pending => 0;
  List<String> get groupMembers => groupFormation.split(',');
  String get startPoint => location;
  String get paymentStatus => dinnerStatus;

  get date => null;
}
