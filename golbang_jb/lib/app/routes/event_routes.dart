import 'package:go_router/go_router.dart';
import 'package:golbang/models/club.dart';
import 'package:golbang/pages/event/event_create2.dart';
import 'package:golbang/pages/event/event_update2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/enum/event.dart';
import '../../models/event.dart';
import '../../models/participant.dart';
import '../../models/profile/member_profile.dart';
import '../../models/responseDTO/CourseResopnseDTO.dart';
import '../../models/responseDTO/GolfClubResponseDTO.dart';
import '../../pages/event/detail/event_detail_page.dart';
import '../../pages/event/event_create1.dart';
import '../../pages/event/event_main.dart';
import '../../pages/event/event_result.dart';
import '../../pages/event/event_result_full_score_card.dart';
import '../../pages/event/event_update1.dart';
import '../../pages/game/overall_score_page.dart';
import '../../pages/game/score_card_page.dart';

final List<GoRoute> eventRoutes = [

  GoRoute(
      path: '/app/events/new-step1',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        return EventsCreate1(startDay: extra?['startDay'] as DateTime);
      }
    ),
  GoRoute(
      path: '/app/events/new-step2',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;

        return EventsCreate2(
            title: extra?['title'] as String,
            selectedClub: extra?['selectedClub'] as Club,
            selectedLocation: extra?['selectedLocation'] as LatLng,
            selectedGolfClub: extra?['selectedGolfClub'] as GolfClubResponseDTO,
            selectedCourse: extra?['selectedCourse'] as CourseResponseDTO,
            startDate: extra?['startDate'] as DateTime,
            endDate: extra?['endDate'] as DateTime,
            selectedParticipants: extra?['selectedParticipants'] as List<ClubMemberProfile>,
            selectedGameMode: extra?['selectedGameMode'] as GameMode
        );
      }
  ),
  GoRoute(
    path: '/app/events/:eventId',
    builder: (context, state) {
      final eventId = int.tryParse(state.pathParameters['eventId']!);
      final extra = state.extra as Map<String, dynamic>?;
      final event = extra?['event'] as Event?;

      return EventDetailPage(
        eventId: eventId,
        event: event,
        from: extra?['from'],
      );
    },
      // eventId 하위 경로
    routes: [
      GoRoute(
          path: 'game',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ScoreCardPage(event: extra?['event'] as Event);
          },
          routes: [
            GoRoute(
              path: 'scores',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return OverallScorePage(event: extra?['event'] as Event);
              },
            ),
          ]
      ),
      GoRoute(
        path: 'result',
        builder: (context, state) {
          final eventId = int.tryParse(state.pathParameters['eventId']!);
          final extra = state.extra as Map<String, dynamic>?;
          bool? isFull = extra?['isFull'];
          if (isFull == true) {
            return EventResultFullScoreCard(eventId: eventId!);
          }
          return EventResultPage(eventId: eventId!);
        },
      ),
      GoRoute(
        path: 'edit-step1',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EventsUpdate1(event: extra?['event']);
        },
      ),
      GoRoute(
        path: 'edit-step2',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EventsUpdate2(
            eventId: extra?['eventId'] as int,
            title: extra?['title'] as String,
            selectedClub: extra?['selectedClub'] as Club,
            selectedLocation:extra?['selectedLocation'] as LatLng,
            selectedGolfClub: extra?['selectedGolfClub'] as GolfClubResponseDTO,
            selectedCourse: extra?['selectedCourse'] as CourseResponseDTO,
            startDate: extra?['startDate'] as DateTime,
            endDate: extra?['endDateTime'] as DateTime,
            selectedParticipants: extra?['selectedParticipants'] as List<ClubMemberProfile>,
            existingParticipants: extra?['existingParticipants']as List<Participant>,
            selectedGameMode: extra?['selectedGameMode'] as GameMode,
          );
        },
      ),
    ]
  ),
];
