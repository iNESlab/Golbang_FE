import 'package:flutter/material.dart';
import '../models/event.dart';

class UpcomingEvents extends StatelessWidget {
  final List<Event> events;

  const UpcomingEvents({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _getBorderColor(event), width: 1.5),
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
                        Text('모임 이름 ${index + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        if (event.isAdmin)
                          const Icon(Icons.admin_panel_settings,
                              color: Colors.green),
                      ],
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _getBorderColor(event), width: 2.0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: _getBorderColor(event),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '이벤트 날짜와 시간 ${index + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('장소: 장소 ${index + 1}'),
                              Row(
                                children: [
                                  const Text('회비 납부 '),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: _getBorderColor(event),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      event.paymentStatus,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getBorderColor(Event event) {
    if (event.paymentStatus == '완료') {
      return Colors.cyan;
    } else if (event.paymentStatus == '미납') {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }
}
