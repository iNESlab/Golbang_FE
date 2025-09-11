import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_enum.dart';
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
    if (currentTime.isAfter(endDateTime)) {
      return _buildResultButton(context);
    } else if (currentTime.isAfter(startDateTime)) {
      final button = _buildScoreCardButton(context, ref);
      return button ?? const SizedBox.shrink(); // null이면 빈 위젯 반환
    } else {
      return _buildCountdownButton();
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
        minimumSize: const Size(double.infinity, 50),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero
        ),
      ),
      child: const Text("결과 조회"),
    );
  }

  Widget? _buildScoreCardButton(BuildContext context, WidgetRef ref) {
    if (myStatus != 'ACCEPT' && myStatus != 'PARTY') return null;

    final isGameInProgress = ref.watch(
      gameInProgressProvider.select((map) => map[event.eventId] ?? false),
    );

    return ElevatedButton(
      onPressed: () {
        if (!isGameInProgress) {
          ref.read(gameInProgressProvider.notifier).startGame(event.eventId);
        }
        context.push('/app/events/${event.eventId}/game', extra: {'event': event});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero
        ),
      ),
      child: Text(isGameInProgress ? "게임 진행 중" : "게임 시작"),
    );
  }

  Widget _buildCountdownButton() {
    final diff = startDateTime.difference(currentTime);
    final label = diff.inDays > 0
        ? "${diff.inDays}일 후 시작"
        : diff.inHours > 0
        ? "${diff.inHours}시간 후 시작"
        : diff.inMinutes > 0
        ? "${diff.inMinutes}분 후 시작"
        : "곧 시작";

    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero
        ),
      ),
      child: Text(label),
    );
  }
}
