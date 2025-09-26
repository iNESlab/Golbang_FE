// lib/pages/event/detail/event_detail_body.dart
import 'package:flutter/material.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/models/participant.dart';
import 'package:golbang/pages/event/detail/widget/event_header_section.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'widget/course_info_card.dart';
import 'widget/event_group_panel.dart';

class EventDetailBody extends StatelessWidget {
  final Event event;
  final double fontSizeXLarge;
  final double fontSizeLarge;
  final double fontSizeMedium;
  final double fontSizeSmall;
  final LatLng? selectedLocation;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int? myGroup;
  final Orientation orientation;
  final double screenWidth;
  final List<Participant> participants;

  const EventDetailBody({
    super.key,
    required this.event,
    required this.fontSizeXLarge,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
    required this.fontSizeSmall,
    required this.selectedLocation,
    required this.startDateTime,
    required this.endDateTime,
    required this.myGroup,
    required this.orientation,
    required this.screenWidth,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventHeaderSection(
            event: event,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            fontSizeXLarge: fontSizeXLarge,
            fontSizeMedium: fontSizeMedium,
            fontSizeLarge: fontSizeLarge,
            screenWidth: screenWidth,
          ),
          const SizedBox(height: 10),
          Text('인원 수: ${participants.length}명, 참석자 수: ${event.acceptCount}명', style: TextStyle(fontSize: fontSizeLarge)),
          Text('참석률: ${participants.isNotEmpty ? (event.acceptCount / participants.length * 100).toStringAsFixed(1) : 0}%', style: TextStyle(fontSize: fontSizeLarge)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('나의 조: ', style: TextStyle(fontSize: fontSizeLarge)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '$myGroup',
                  style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          EventGroupPanel(
            participants: participants,
            fontSizeLarge: fontSizeLarge,
            fontSizeMedium: fontSizeMedium,
          ),
          if (selectedLocation != null) ...[
            const SizedBox(height: 16),
            CourseInfoCard(
              selectedLocation: selectedLocation,
              golfClubName: event.golfClub!.golfClubName,
              event: event,
              fontSizeLarge: fontSizeLarge,
              fontSizeMedium: fontSizeMedium,
            ),
          ],
        ],
      ),
    );
  }
}
