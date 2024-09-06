/*
pages/event/widgets/event_header.dart
이벤트의 제목, 장소, 시간, 모드, 핸디캡 토글 등을 표시
*/
import 'package:flutter/material.dart';

class EventHeader extends StatelessWidget {
  final String eventTitle;
  final String location;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String gameMode;
  final bool isHandicapEnabled;

  const EventHeader({
    required this.eventTitle,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.gameMode,
    required this.isHandicapEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventTitle,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text('$location | ${startDateTime.toLocal()} - ${endDateTime.toLocal()}'),
        Text('모드: $gameMode'),
        SwitchListTile(
          title: Text('핸디캡 적용'),
          value: isHandicapEnabled,
          onChanged: (bool value) {
            // 핸디캡 적용 상태 변경 로직
          },
        ),
      ],
    );
  }
}
