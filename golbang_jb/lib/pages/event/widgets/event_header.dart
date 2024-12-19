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
  final String participantCount;
  final String myGroupType;
  final bool isHandicapEnabled;
  final ValueChanged<bool> onHandicapToggle;

  const EventHeader({
    required this.eventTitle,
    required this.location,
    required this.startDateTime,
    required this.endDateTime,
    required this.gameMode,
    required this.participantCount,
    required this.myGroupType,
    required this.isHandicapEnabled,
    required this.onHandicapToggle,
  });

  static const Map<String, String> gameModeDisplayNames = {
    'SP': '스트로크',
    'MP': '매치플레이' // 새로 추가될 수 있는 값
    // 'BB': '베스트볼',  // 새로 추가될 수 있는 값
    // 'AP': '알터네이트샷'  // 새로 추가될 수 있는 값
  };

  String get displayGameMode {
    return gameModeDisplayNames[gameMode] ?? '알 수 없음';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/golf_icon.png', // 이벤트 아이콘 (원래 스타일)
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventTitle,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${startDateTime.toLocal().toIso8601String().split('T').first} • ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')} ~ ${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '장소: $location',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '게임모드: $displayGameMode',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '참여 인원: $participantCount명',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Handicap',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Transform.scale(
                          scale: 0.8, // 토글 버튼 크기 조절
                          child: Switch(
                            value: isHandicapEnabled,
                            onChanged: onHandicapToggle,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.grey,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
