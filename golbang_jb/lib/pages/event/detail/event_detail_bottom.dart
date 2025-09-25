import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../provider/event/game_in_progress_provider.dart';
import 'package:go_router/go_router.dart';

class EventDetailBottomBar extends ConsumerWidget {
  final Event event;
  final String myStatus;
  final DateTime currentTime;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const EventDetailBottomBar({
    super.key,
    required this.event,
    required this.myStatus,
    required this.currentTime,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildMainContent(context, ref),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    if (currentTime.isAfter(endDateTime)) {
      return _buildResultButton(context);
    } else if (currentTime.isAfter(startDateTime)) {
      final button = _buildScoreCardButton(context, ref);
      return button ?? const SizedBox.shrink();
    } else {
      return _buildCountdownButton(context, ref);
    }
  }

  Widget _buildResultButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.push('/app/events/${event.eventId}/result', extra: {'eventId': event.eventId});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 20),
          const SizedBox(width: 8),
          const Text(
            "결과 조회",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildScoreCardButton(BuildContext context, WidgetRef ref) {
    final isGameInProgress = ref.watch(
      gameInProgressProvider.select((map) => map[event.eventId] ?? false),
    );

    // 참가 상태에 따라 게임 시작 버튼 활성화/비활성화 결정
    bool canParticipate = (myStatus == 'ACCEPT' || myStatus == 'PARTY');

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canParticipate ? () {
              if (!isGameInProgress) {
                ref.read(gameInProgressProvider.notifier).startGame(event.eventId);
              }
              context.push('/app/events/${event.eventId}/game', extra: {'event': event});
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canParticipate ? Colors.green : Colors.grey.shade400,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isGameInProgress ? Icons.play_circle_filled : Icons.play_arrow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isGameInProgress 
                      ? "게임 진행 중" 
                      : (canParticipate ? "게임 시작" : "참가 불가"),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _enterClubChatRoom(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    "모임 채팅방",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownButton(BuildContext context, WidgetRef ref) {
    final diff = startDateTime.difference(currentTime);
    final label = diff.inDays > 0
        ? "${diff.inDays}일 후 시작"
        : diff.inHours > 0
        ? "${diff.inHours}시간 후 시작"
        : diff.inMinutes > 0
        ? "${diff.inMinutes}분 후 시작"
        : "곧 시작";

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade700,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _enterClubChatRoom(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    "모임 채팅방",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 모임 채팅방 입장
  void _enterClubChatRoom(BuildContext context) {
    // 이벤트의 클럽 ID를 사용하여 클럽 채팅방으로 이동
    final clubId = event.club?.clubId;
    if (clubId != null) {
      final chatRoomId = 'club_$clubId';
      
      // Club을 ClubProfile로 변환
      final clubProfile = event.club;
      
      // 임시 이벤트 객체 생성 (채팅방 ID만 필요)
      final tempEvent = Event(
        eventId: clubId,
        memberGroup: 0,
        eventTitle: '${event.club?.name ?? '모임'} 채팅방',
        site: '모임 채팅방',
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now().add(const Duration(hours: 1)),
        repeatType: 'NONE',
        gameMode: 'SP',
        alertDateTime: '',
        participantsCount: 0,
        partyCount: 0,
        acceptCount: 0,
        denyCount: 0,
        pendingCount: 0,
        myParticipantId: 0,
        participants: [],
        club: clubProfile,
      );
      
      context.push('/app/events/$clubId/chat', extra: {
        'event': tempEvent,
        'chatRoomType': 'club',
        'chatRoomId': chatRoomId,
      });
    }
  }

}
