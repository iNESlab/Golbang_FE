// lib/pages/event/detail/event_header_section.dart
import 'package:flutter/material.dart';
import '../../../../models/event.dart';

class EventHeaderSection extends StatelessWidget {
  final Event event;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final double fontSizeXLarge;
  final double fontSizeLarge;
  final double fontSizeMedium;
  final double screenWidth;

  const EventHeaderSection({
    super.key,
    required this.event,
    required this.startDateTime,
    required this.endDateTime,
    required this.fontSizeXLarge,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: screenWidth * 0.1,
          backgroundImage: event.club!.image.startsWith('https')
              ? NetworkImage(event.club!.image)
              : AssetImage(event.club!.image) as ImageProvider,
          backgroundColor: Colors.transparent,
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.eventTitle,
                style: TextStyle(
                  fontSize: fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${startDateTime.toIso8601String().split('T').first} • ${startDateTime.hour}:${startDateTime.minute.toString().padLeft(2, '0')} ~ ${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}${startDateTime.toIso8601String().split('T').first != endDateTime.toIso8601String().split('T').first ? ' (${endDateTime.toIso8601String().split('T').first})' : ''}',
                style: TextStyle(fontSize: fontSizeMedium, overflow: TextOverflow.ellipsis),
              ),
              Text('장소: ${event.golfClub!.golfClubName}', style: TextStyle(fontSize: fontSizeMedium)),
              Text('게임모드: ${event.displayGameMode}', style: TextStyle(fontSize: fontSizeMedium)),
            ],
          ),
        ),
      ],
    );
  }
}
