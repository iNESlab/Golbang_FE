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
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: _getBorderColor(event.dinnerStatus), width: 1.5),
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
                              color: Colors.green, size: 25),
                      ],
                    ),
                    Text('일정 날짜와 시간 ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('장소: ${event.location}'),
                    Row(
                      children: [
                        const Text('참석 여부: '),
                        _buildStatusButton(event.dinnerStatus),
                        const SizedBox(width: 8.0),
                        const Text('회비: '),
                        _buildPaymentButton(event.paymentStatus),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status) {
    Color color;
    switch (status) {
      case '참석':
        color = Colors.cyan;
        break;
      case '불참':
        color = Colors.red;
        break;
      case '미정':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(40, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        status,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentButton(String paymentStatus) {
    Color color;
    switch (paymentStatus) {
      case '완료':
        color = Colors.deepPurple;
        break;
      case '미납':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(40, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        paymentStatus,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Color _getBorderColor(String status) {
    switch (status) {
      case '참석':
        return Colors.cyan;
      case '불참':
        return Colors.red;
      case '미정':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
