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
import '../../pages/event/result/event_result.dart';
import '../../pages/event/result/event_result_full_score_card.dart';
import '../../pages/event/event_update1.dart';
import '../../pages/game/overall_score_page.dart';
import '../../pages/game/score_card_page.dart';
import '../../pages/chat/club_chat_page.dart';

final List<GoRoute> eventRoutes = [
  // /app/events/new-step1
  GoRoute(
    path: '/app/events/new-step1',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return NoTransitionPage(
        key: state.pageKey,
        child: EventsCreate1(
          startDay: extra?['startDay'] as DateTime?,
        ),
      );
    },
  ),

  // /app/events/new-step2
  GoRoute(
    path: '/app/events/new-step2',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      return NoTransitionPage(
        key: state.pageKey,
        child: EventsCreate2(
          title: extra?['title'] as String,
          selectedClub: extra?['selectedClub'] as Club?,
          selectedLocation: extra?['selectedLocation'] as LatLng?,
          selectedGolfClub: extra?['selectedGolfClub'] as GolfClubResponseDTO,
          selectedCourse: extra?['selectedCourse'] as CourseResponseDTO,
          startDate: extra?['startDate'] as DateTime,
          endDate: extra?['endDate'] as DateTime,
          selectedParticipants: extra?['selectedParticipants'] as List<ClubMemberProfile>,
          selectedGameMode: extra?['selectedGameMode'] as GameMode,
        ),
      );
    },
  ),

  // /app/events/:eventId
  GoRoute(
    path: '/app/events/:eventId',
    pageBuilder: (context, state) {
      final eventId = int.tryParse(state.pathParameters['eventId']!) as int;
      final extra = state.extra as Map<String, dynamic>?;
      return NoTransitionPage(
        key: state.pageKey,
        child: EventDetailPage(
          eventId: eventId,
          from: extra?['from'],
        ),
      );
    },

    // 하위 경로
    routes: [
      // /app/events/:eventId/game
      GoRoute(
        path: 'game',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final event = extra?['event'] as Event;
          return NoTransitionPage(
            key: state.pageKey,
            child: ScoreCardPage(event: event),
          );
        },
        routes: [
          // /app/events/:eventId/game/scores
          GoRoute(
            path: 'scores',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final event = extra?['event'] as Event;
              return NoTransitionPage(
                key: state.pageKey,
                child: OverallScorePage(event: event),
              );
            },
          ),
        ],
      ),

      // /app/events/:eventId/result
      GoRoute(
        path: 'result',
        pageBuilder: (context, state) {
          final eventId = int.parse(state.pathParameters['eventId']!);
          final extra = state.extra as Map<String, dynamic>?;
          final isFull = (extra?['isFull'] as bool?) ?? false;

          return NoTransitionPage(
            key: state.pageKey,
            child: isFull
                ? EventResultFullScoreCard(eventId: eventId)
                : EventResultPage(eventId: eventId),
          );
        },
      ),

      // /app/events/:eventId/edit-step1
      GoRoute(
        path: 'edit-step1',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final event = extra?['event'] as Event;
          return NoTransitionPage(
            key: state.pageKey,
            child: EventsUpdate1(event: event),
          );
        },
      ),

      // /app/events/:eventId/edit-step2
      GoRoute(
        path: 'edit-step2',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NoTransitionPage(
            key: state.pageKey,
            child: EventsUpdate2(
              eventId: extra?['eventId'] as int,
              title: extra?['title'] as String,
              selectedClub: extra?['selectedClub'] as Club?,
              selectedLocation: extra?['selectedLocation'] as LatLng,
              selectedGolfClub: extra?['selectedGolfClub'] as GolfClubResponseDTO,
              selectedCourse: extra?['selectedCourse'] as CourseResponseDTO,
              startDate: extra?['startDate'] as DateTime,
              endDate: extra?['endDate'] as DateTime,
              selectedParticipants: extra?['selectedParticipants'] as List<ClubMemberProfile>,
              existingParticipants: extra?['existingParticipants'] as List<Participant>,
              selectedGameMode: extra?['selectedGameMode'] as GameMode,
            ),
          );
        },
      ),

      // /app/events/:eventId/chat
      GoRoute(
        path: 'chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ClubChatPage(
            event: extra?['event'] as Event,
            chatRoom: extra?['chatRoom'],
          );
        },
      ),
    ],
  ),
];
