import 'package:flutter/material.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/event/event_detail.dart';
import 'package:golbang/services/participant_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repoisitory/secure_storage.dart';

class UpcomingEvents extends ConsumerStatefulWidget {
  final List<Event> events;

  const UpcomingEvents({super.key, required this.events});

  @override
  UpcomingEventsState createState() => UpcomingEventsState();
}

class UpcomingEventsState extends ConsumerState<UpcomingEvents> {
  late ParticipantService _participantService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = ref.watch(secureStorageProvider);
    _participantService = ParticipantService(storage);
  }

  Future<void> _handleStatusChange(String newStatus, int participantId, Event event) async {
    bool success = await _participantService.updateParticipantStatus(participantId, newStatus);
    if (success) {
      setState(() {
        final participant = event.participants.firstWhere(
              (p) => p.participantId == participantId,
        );
        participant.statusType = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기와 폰트 크기 설정
    double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이

    // 폰트 크기를 화면 너비에 비례하여 설정
    double fontSize = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.04; // 큰 화면에서는 폰트 크기 증가
    double buttonFontSize = screenWidth > 600 ? screenWidth * 0.03 : screenWidth * 0.035; // 버튼 텍스트 크기

    double itemHeight = screenHeight * 0.1; // 각 이벤트 항목의 높이

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: itemHeight, // 화면 크기에 따라 리스트 높이 조정
        child: ListView.builder(
          itemCount: widget.events.length,
          itemBuilder: (context, index) {
            final event = widget.events[index];

            // myParticipantId와 동일한 participantId의 statusType을 가져옴
            final participant = event.participants.firstWhere(
                  (p) => p.participantId == event.myParticipantId,
              orElse: () => event.participants[0],
            );
            String statusType = participant.statusType;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailPage(event: event),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005, horizontal: screenWidth * 0.03),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005, horizontal: screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _getBorderColor(statusType),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(screenHeight * 0.0025),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.eventTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize, // 반응형 폰트 크기
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${event.startDateTime.toLocal()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize - 2, // 반응형 폰트 크기
                        ),
                      ),
                      Text(
                        '장소: ${event.site}',
                        style: TextStyle(
                          fontSize: fontSize - 2, // 반응형 폰트 크기
                        ),
                      ),
                      Row(
                        children: [
                          Text('참석 여부: ',
                            style: TextStyle(
                              fontSize: fontSize - 2, // 반응형 폰트 크기
                            ),
                          ),
                          _buildStatusButton(statusType, event, fontSize, buttonFontSize, screenWidth), // 버튼 크기 및 폰트 크기 전달
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, Event event, double fontSize, double buttonFontSize, double screenWidth) {
    Color color = _getStatusColor(status);
    int participantId = event.participants.isNotEmpty
        ? event.participants.firstWhere(
          (p) => p.participantId == event.myParticipantId,
      orElse: () => event.participants[0],
    ).participantId
        : -1; // 참가자가 없는 경우를 처리

    return ElevatedButton(
      onPressed: participantId != -1
          ? () async {
        await _handleStatusChange(status == 'ACCEPT'
            ? 'DENY'
            : status == 'DENY'
            ? 'PARTY'
            : 'ACCEPT', participantId, event);
      }
          : null, // 참가자가 없는 경우 버튼 비활성화
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(screenWidth > 600 ? 100 : 80, 40), // 화면 크기와 버튼 크기 조정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(fontSize: buttonFontSize, color: Colors.white), // 반응형 버튼 텍스트 크기
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACCEPT':
        return '참석';
      case 'PARTY':
        return '참석 · 회식';
      case 'DENY':
        return '불참';
      default:
        return '미정';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PARTY':
        return const Color(0xFF4D08BD); // 보라색
      case 'ACCEPT':
        return const Color(0xFF08BDBD); // 파란색
      case 'DENY':
        return const Color(0xFFF21B3F); // 빨간색
      case 'PENDING':
      default:
        return const Color(0xFF7E7E7E); // 회색
    }
  }

  Color _getBorderColor(String status) {
    return _getStatusColor(status);
  }
}
