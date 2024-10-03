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
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: widget.events.length,
          itemBuilder: (context, index) {
            final event = widget.events[index];

            // 수정된 부분: myParticipantId와 동일한 participantId의 statusType을 가져옴
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
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                  contentPadding: const EdgeInsets.all(4),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.eventTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${event.startDateTime.toLocal()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('장소: ${event.site}'),
                      Row(
                        children: [
                          const Text('참석 여부: '),
                          _buildStatusButton(statusType, event),
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

  Widget _buildStatusButton(String status, Event event) {
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
        minimumSize: const Size(40, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        _getStatusText(status),
        style: const TextStyle(fontSize: 12, color: Colors.white),
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
