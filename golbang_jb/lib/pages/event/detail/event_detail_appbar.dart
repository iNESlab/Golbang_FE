import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event.dart';
import '../../../provider/event/event_state_notifier_provider.dart';
import '../../../provider/event/game_in_progress_provider.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/event_service.dart';
import '../../../widgets/sections/show_email_recipient_dialog.dart';
import '../../../utils/email.dart';
import '../../../utils/excelFile.dart';
import 'package:share_plus/share_plus.dart';


PreferredSizeWidget buildEventDetailAppBar(
    BuildContext context,
    WidgetRef ref,
    Event event,
    DateTime currentTime,
    List<dynamic> participants,
    ) {
  late EventService eventService;
  final screenWidth = MediaQuery.of(context).size.width;
  final orientation = MediaQuery.of(context).orientation;
  final double iconSize = screenWidth * (orientation == Orientation.portrait ? 0.06 : 0.04);
  final double fontSize = screenWidth * (orientation == Orientation.portrait ? 0.05 : 0.035);
  final bool isEnd = event.endDateTime.isBefore(currentTime);


  void editEvent() {
    context.push('/app/events/${event.eventId}/edit-step1', extra: {'event': event});
  }

  void deleteEvent() async {
    try{
      await ref.read(eventStateNotifierProvider.notifier).deleteEvent(event.eventId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 삭제되었습니다')),
      );
      context.go('/app/events?refresh=${DateTime.now().millisecondsSinceEpoch}');
    }  catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void endEvent(Event event) async {
    try {
      await ref.read(eventStateNotifierProvider.notifier).endEvent(event);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시합이 종료되었습니다')),
      );
    } catch (e) {
      log('Error ending event: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  return AppBar(
    title: Text(event.eventTitle, style: TextStyle(fontSize: fontSize)),
    leading: IconButton(
      icon: Icon(Icons.arrow_back, size: iconSize),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/app/events');
        }
      },
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.attach_email_rounded, size: iconSize),
        onPressed: () async {
          final isGameInProgress = ref.read(
            gameInProgressProvider.select((map) => map[event.eventId] ?? false),
          );

          final selectedRecipients =
          await showEmailRecipientDialog(context, event.participants);

          if (selectedRecipients.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이메일 받을 참가자를 선택해주세요.')),
            );
            return;
          }

          if (isGameInProgress) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('경고'),
                content: const Text(
                    '게임 진행 중인 경우 데이터가 15분마다 동기화되어, 현재 점수와 일치하지 않을 수 있습니다. 계속 추출하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop();
                      exportAndSendEmail(context, event, selectedRecipients, participants);
                    },
                    child: const Text('추출'),
                  ),
                ],
              ),
            );
          } else {
            exportAndSendEmail(context, event, selectedRecipients, participants);
          }
        },
      ),
      PopupMenuButton<String>(
        onSelected: (String value) async {
          switch (value) {
            case 'share':
              _shareEvent(event);
              break;
            case 'end':
            // 재확인 모달
              final ok = await _confirmEndEvent(context);
              if (ok) endEvent(event);
              break;
            case 'edit':
              editEvent();
              break;
            case 'delete':
              deleteEvent();
              break;
            default:
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          if (!isEnd && currentTime.isBefore(event.startDateTime.add(const Duration(minutes: 30))))
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('수정'),
            ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Text('삭제'),
          ),
          const PopupMenuItem<String>(
            value: 'share',
            child: Text('공유'),
          ),
          if (!isEnd)
            const PopupMenuItem<String>(
              value: 'end',
              child: Text('시합 종료'),
            ),
        ],
      ),
    ],
  );
}

void _shareEvent(Event event) {
  // final String eventLink = "${dotenv.env['API_HOST']}/app/events/${event.eventId}";
  Share.share(
    '이벤트를 확인해보세요!\n\n'
        '제목: ${event.eventTitle}\n'
        '날짜: ${event.startDateTime.toIso8601String().split('T').first}\n'
        '장소: ${event.site}\n\n'
        // '자세히 보기: $eventLink',
  );
}

// 1) 공통 확인 다이얼로그 helper
Future<bool> _confirmEndEvent(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('시합 종료'),
      content: const Text('정말로 시합을 종료하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          child: const Text('종료'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> exportAndSendEmail(
    BuildContext context, Event event, List<String> recipients, List<dynamic> participants) async {
  final filePath = await createScoreExcelFile(
    eventId: event.eventId,
    participants: participants,
    teamAScores: null, // 리팩토링된 상태에서는 필요 시 인자로 받게 수정
    teamBScores: null,
  );

  if (filePath != null) {
    try {
      await sendEmail(
        body:
        '제목: ${event.eventTitle}\n 날짜: ${event.startDateTime.toIso8601String().split('T').first}\n 장소: ${event.site}',
        subject:
        '${event.club?.name}_${event.startDateTime.toIso8601String().split('T').first}_${event.eventTitle}',
        recipients: recipients,
        attachmentPaths: [filePath],
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 전송 실패: $error')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장 경로를 찾을 수 없습니다.')),
    );
  }
}
