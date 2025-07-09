import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/event/event_detail.dart';
import 'package:golbang/services/participant_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'package:intl/intl.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';

class UpcomingEvents extends ConsumerStatefulWidget {
  final List<Event> events;
  final String date;
  final Future<void> Function()? onEventUpdated;

  const UpcomingEvents({super.key, required this.events, required this.date, this.onEventUpdated,});

  @override
  UpcomingEventsState createState() => UpcomingEventsState();
}

class UpcomingEventsState extends ConsumerState<UpcomingEvents> {
  final ScrollController _scrollController = ScrollController(); // 고유 ScrollController
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
    double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
    Orientation orientation = MediaQuery.of(context).orientation;

    double fontSize = ResponsiveUtils.getUpcomingEventsFontSizeDescription(screenWidth, orientation);
    double eventNoteIconSize = orientation == Orientation.landscape ? screenHeight * 0.25 : screenWidth * 0.3;

    double eventTitleFS = fontSize * 0.9;
    double eventOtherFS = fontSize * 0.8;

    // 오늘 날짜까지의 이벤트만 필터링
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filteredEvents = widget.events.where((event) {
      final eventDay = DateTime(event.startDateTime.year, event.startDateTime.month, event.startDateTime.day);
      return !eventDay.isBefore(today); // 오늘 이전은 제외, 오늘 포함
    }).toList();

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: eventNoteIconSize,
              color: Colors.grey,
            ),
            Text(
              '일정 추가 버튼을 눌러\n이벤트를 만들어보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
          thumbVisibility: true,
          thickness: 5.0,
          controller: _scrollController, // 고유 ScrollController
          child: ListView.builder( // 이벤트가 있을 때
            controller: _scrollController, // 고유 ScrollController
            primary: false,
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              final participant = event.participants.firstWhere(
                    (p) => p.participantId == event.myParticipantId,
                orElse: () => event.participants[0],
              );
              String statusType = participant.statusType;

              // 날짜 및 시간 포맷
              final formattedDateTime = DateFormat("yyyy-MM-dd a h:mm", Localizations.localeOf(context).toString())
                  .format(event.startDateTime);

              String golfClubName = "";
              if (event.golfClub == null ||
                  event.golfClub?.golfClubName == null ||
                  event.golfClub!.golfClubName.isEmpty ||
                  event.golfClub!.golfClubName == "unknown_site") {
                golfClubName = event.site ?? "";
              } else {
                golfClubName = event.golfClub!.golfClubName;
              }

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailPage(event: event),
                    ),
                  );

                  log('수정 여부: $result');

                  if (result == true) {
                    // 이벤트 삭제 후 목록 새로고침
                    await widget.onEventUpdated!(); // 데이터 다시 로딩
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.005,
                    horizontal: screenWidth * 0.03,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.005,
                    horizontal: screenWidth * 0.03,
                  ),
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
                        offset: const Offset(0, 3),
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
                                fontSize: eventTitleFS,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formattedDateTime,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: eventOtherFS,
                          ),
                        ),
                        Text(
                          '장소: $golfClubName',
                          style: TextStyle(
                            fontSize: eventOtherFS,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '참석 여부: ',
                              style: TextStyle(
                                fontSize: eventOtherFS,
                              ),
                            ),
                            _buildStatusButton(
                                statusType, event, fontSize, eventOtherFS, screenWidth, orientation),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

      );
    }



  Widget _buildStatusButton(String status, Event event, double fontSize, double buttonFontSize, double screenWidth, Orientation orientation) {
    Color color = _getStatusColor(status);
    int participantId = event.participants.isNotEmpty
        ? event.participants.firstWhere(
          (p) => p.participantId == event.myParticipantId,
      orElse: () => event.participants[0],
    ).participantId
        : -1; // 참가자가 없는 경우를 처리

    // 현재 날짜와 이벤트 날짜 비교
    bool isPastEvent = event.startDateTime.isBefore(DateTime.now());

    double buttonWidth = ResponsiveUtils.getUpcomingEventsButtonWidth(screenWidth, orientation);
    double buttonHeight = ResponsiveUtils.getUpcomingEventsButtonHeight(screenWidth, orientation);
    return ElevatedButton(
      onPressed: participantId != -1 && !isPastEvent
          ? () async {
        await _handleStatusChange(status == 'ACCEPT'
            ? 'DENY'
            : status == 'DENY'
            ? 'PARTY'
            : 'ACCEPT', participantId, event);
      }
          : null, // 과거 이벤트이거나 참가자가 없는 경우 버튼 비활성화
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(buttonWidth, buttonHeight), // 화면 크기와 버튼 크기 조정
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        // 비활성화된 버튼 스타일 유지
        disabledBackgroundColor: color.withOpacity(0.6),
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
